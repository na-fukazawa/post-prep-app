import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const app = express();
const port = process.env.PORT ? Number(process.env.PORT) : 8787;
const model = process.env.OPENAI_MODEL || "gpt-4o-mini";

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

app.get("/health", (_req, res) => {
  res.json({ ok: true });
});

async function handleFormat(req, res) {
  const text = req.body?.text;
  const title = req.body?.title ?? "";
  const template = req.body?.template ?? "";
  if (typeof text !== "string" || text.trim().length === 0) {
    return res.status(400).json({ error: "text_required" });
  }
  if (text.length > 12000) {
    return res.status(413).json({ error: "text_too_large" });
  }

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: "missing_openai_api_key" });
  }

  const payload = {
    model,
    temperature: 0,
    input: [
      {
        role: "system",
        content:
          "Format the source text into the provided template. Output only the final announcement text with no extra commentary. If placeholders {title} or {body} appear in the template, replace them with the given title and the formatted body. If no placeholders are present, follow the template's style and include the title and main content naturally. If the template is empty, output a clean announcement with the title on top (if provided) and the formatted body below.",
      },
      {
        role: "user",
        content: [
          "Title:",
          typeof title === "string" ? title : "",
          "",
          "Template:",
          typeof template === "string" ? template : "",
          "",
          "Source:",
          text,
        ].join("\n"),
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

  return res.json({ data: parsed, model: responseJson?.model, usage: responseJson?.usage });
}

app.post("/format", handleFormat);
app.post("/extract", handleFormat);

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`format server listening on http://localhost:${port}`);
});
