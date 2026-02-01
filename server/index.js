import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import crypto from "crypto";

import {
  addMonthlyCost,
  getCachedFormatted,
  getMonthKeyUTC,
  getMonthlyCost,
  setCachedFormatted,
} from "./storage.js";

dotenv.config();

const app = express();
const port = process.env.PORT ? Number(process.env.PORT) : 8787;
const model = process.env.OPENAI_MODEL || "gpt-4o-mini";

const PRICE_INPUT = Number(process.env.PRICE_INPUT ?? "0.25");
const PRICE_CACHE = Number(process.env.PRICE_CACHE ?? "0.025");
const PRICE_OUTPUT = Number(process.env.PRICE_OUTPUT ?? "2.0");

const BUDGET_USD = Number(process.env.BUDGET_USD ?? "1.0");
const BUDGET_GUARD = Math.min(Number(process.env.BUDGET_GUARD ?? "0.95"), BUDGET_USD);
const CACHE_ENABLED = process.env.CACHE_ENABLED !== "false";
const PROMPT_VERSION = "v1";

app.use(cors());
app.use(express.json({ limit: "1mb" }));

const FORMAT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    formatted_text: { type: "string", description: "Final formatted announcement text" },
  },
  required: ["formatted_text"],
};

function extractOutputText(responseJson) {
  if (typeof responseJson?.output_text === "string") {
    return responseJson.output_text;
  }
  if (!Array.isArray(responseJson?.output)) return "";
  const parts = [];
  for (const item of responseJson.output) {
    if (item?.type !== "message" || !Array.isArray(item.content)) continue;
    for (const part of item.content) {
      if (part?.type === "output_text" && typeof part.text === "string") {
        parts.push(part.text);
      }
    }
  }
  return parts.join("");
}

function buildFallbackFormatted({ text, title, template }) {
  const trimmedRaw = typeof text === "string" ? text.trim() : "";
  const trimmedTitle = typeof title === "string" ? title.trim() : "";
  const trimmedTemplate = typeof template === "string" ? template.trim() : "";
  if (!trimmedTemplate) {
    if (!trimmedTitle) return trimmedRaw;
    if (!trimmedRaw) return trimmedTitle;
    return `${trimmedTitle}\n\n${trimmedRaw}`;
  }

  let output = trimmedTemplate;
  output = output.replaceAll("{{title}}", trimmedTitle);
  output = output.replaceAll("{title}", trimmedTitle);
  output = output.replaceAll("{{body}}", trimmedRaw);
  output = output.replaceAll("{body}", trimmedRaw);

  const hasTitleToken = trimmedTemplate.includes("{title}") || trimmedTemplate.includes("{{title}}");
  const hasBodyToken = trimmedTemplate.includes("{body}") || trimmedTemplate.includes("{{body}}");
  if (hasTitleToken || hasBodyToken) {
    return output.trim();
  }

  const fallbackBody = trimmedTitle ? `${trimmedTitle}\n\n${trimmedRaw}` : trimmedRaw;
  if (!fallbackBody) return output.trim();
  return `${output}\n\n${fallbackBody}`.trim();
}

function buildCacheKey({ text, title, template, prompt }) {
  return crypto
    .createHash("sha256")
    .update([model, PROMPT_VERSION, prompt ?? "", title ?? "", template ?? "", text ?? ""].join("|"))
    .digest("hex");
}

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

async function handleFormat(req, res) {
  const text = req.body?.text;
  const title = req.body?.title ?? "";
  const template = req.body?.template ?? "";
  const prompt = typeof req.body?.prompt === "string" ? req.body.prompt : "";
  if (typeof text !== "string" || text.trim().length === 0) {
    return res.status(400).json({ error: "text_required" });
  }
  if (text.length > 12000) {
    return res.status(413).json({ error: "text_too_large" });
  }

  const monthKey = getMonthKeyUTC();
  const currentCost = getMonthlyCost(monthKey);
  const fallbackFormatted = buildFallbackFormatted({ text, title, template });
  if (currentCost >= BUDGET_GUARD) {
    return res.json({
      data: { formatted_text: fallbackFormatted },
      budget_exceeded: true,
      month_cost_usd: currentCost,
      budget_guard_usd: BUDGET_GUARD,
    });
  }

  const cacheKey = buildCacheKey({ text, title, template, prompt });
  if (CACHE_ENABLED) {
    const cached = getCachedFormatted(cacheKey);
    if (cached) {
      return res.json({
        data: { formatted_text: cached },
        cache_hit: true,
        month_cost_usd: currentCost,
        budget_guard_usd: BUDGET_GUARD,
      });
    }
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: "missing_openai_api_key" });
  }

  const systemContent = prompt.trim().length
    ? "Format the input according to the user's instruction. Output only a JSON object that matches the schema."
    : "Format the source text into the provided template. Output only the final announcement text with no extra commentary. If placeholders {title} or {body} appear in the template, replace them with the given title and the formatted body. If no placeholders are present, follow the template's style and include the title and main content naturally. If the template is empty, output a clean announcement with the title on top (if provided) and the formatted body below.";
  const userContent = prompt.trim().length
    ? prompt.trim()
    : [
        "Title:",
        typeof title === "string" ? title : "",
        "",
        "Template:",
        typeof template === "string" ? template : "",
        "",
        "Source:",
        text,
      ].join("\n");

  const payload = {
    model,
    temperature: 0,
    input: [
      {
        role: "system",
        content: systemContent,
      },
      {
        role: "user",
        content: userContent,
      },
    ],
    text: {
      format: {
        type: "json_schema",
        name: "format_announcement",
        strict: true,
        schema: FORMAT_SCHEMA,
      },
    },
  };

  let responseJson;
  try {
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const detail = await response.text();
      if (response.status === 429 && detail.includes("insufficient_quota")) {
        return res.json({
          data: { formatted_text: fallbackFormatted },
          budget_exceeded: true,
          month_cost_usd: currentCost,
          budget_guard_usd: BUDGET_GUARD,
        });
      }
      return res.status(response.status).json({ error: "openai_error", detail });
    }
    responseJson = await response.json();
  } catch (err) {
    return res.status(502).json({ error: "openai_unreachable" });
  }

  const outputText = extractOutputText(responseJson);
  if (!outputText) {
    return res.status(502).json({ error: "empty_output" });
  }

  let parsed;
  try {
    parsed = JSON.parse(outputText);
  } catch (err) {
    return res.status(502).json({ error: "json_parse_error", detail: outputText });
  }

  if (!parsed || typeof parsed.formatted_text !== "string" || parsed.formatted_text.trim().length === 0) {
    return res.status(502).json({ error: "invalid_formatted_text" });
  }

  const usage = responseJson?.usage ?? {};
  const inputTokens = Number(usage?.input_tokens) || 0;
  const outputTokens = Number(usage?.output_tokens) || 0;
  const cachedTokens = Number(usage?.input_tokens_details?.cached_tokens) || 0;
  const billableInput = Math.max(0, inputTokens - cachedTokens);
  const requestCostUsd =
    billableInput / 1e6 * PRICE_INPUT + cachedTokens / 1e6 * PRICE_CACHE + outputTokens / 1e6 * PRICE_OUTPUT;
  const monthCostUsd = addMonthlyCost(monthKey, requestCostUsd);

  if (CACHE_ENABLED) {
    setCachedFormatted(cacheKey, parsed.formatted_text);
  }

  return res.json({
    data: parsed,
    model: responseJson?.model,
    usage: responseJson?.usage,
    cost: {
      request_usd: requestCostUsd,
      month_usd: monthCostUsd,
      month_key: monthKey,
    },
    month_cost_usd: monthCostUsd,
    budget_guard_usd: BUDGET_GUARD,
  });
}

app.post("/format", handleFormat);
app.post("/extract", handleFormat);

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`format server listening on http://localhost:${port}`);
});
