import Database from "better-sqlite3";
import fs from "fs";
import path from "path";

const dataDir = process.env.DATA_DIR || path.resolve(process.cwd(), "data");
fs.mkdirSync(dataDir, { recursive: true });

const dbPath = process.env.DB_PATH || path.join(dataDir, "format_cache.sqlite");
const db = new Database(dbPath);

db.pragma("journal_mode = WAL");
db.pragma("synchronous = NORMAL");

db.exec(`
  CREATE TABLE IF NOT EXISTS usage_monthly (
    month TEXT PRIMARY KEY,
    cost_usd REAL NOT NULL DEFAULT 0,
    updated_at INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS format_cache (
    key TEXT PRIMARY KEY,
    formatted TEXT NOT NULL,
    created_at INTEGER NOT NULL
  );
`);

const getUsageStmt = db.prepare("SELECT cost_usd FROM usage_monthly WHERE month = ?");
const addUsageStmt = db.prepare(
  "INSERT INTO usage_monthly (month, cost_usd, updated_at) VALUES (?, ?, ?) " +
    "ON CONFLICT(month) DO UPDATE SET cost_usd = cost_usd + excluded.cost_usd, updated_at = excluded.updated_at",
);
const getCacheStmt = db.prepare("SELECT formatted FROM format_cache WHERE key = ?");
const setCacheStmt = db.prepare(
  "INSERT INTO format_cache (key, formatted, created_at) VALUES (?, ?, ?) " +
    "ON CONFLICT(key) DO UPDATE SET formatted = excluded.formatted, created_at = excluded.created_at",
);

export function getMonthKeyUTC(date = new Date()) {
  return date.toISOString().slice(0, 7);
}

export function getMonthlyCost(monthKey) {
  const row = getUsageStmt.get(monthKey);
  return row ? Number(row.cost_usd) : 0;
}

export function addMonthlyCost(monthKey, deltaUsd) {
  const now = Date.now();
  addUsageStmt.run(monthKey, deltaUsd, now);
  return getMonthlyCost(monthKey);
}

export function getCachedFormatted(key) {
  const row = getCacheStmt.get(key);
  return row ? row.formatted : null;
}

export function setCachedFormatted(key, formatted) {
  const now = Date.now();
  setCacheStmt.run(key, formatted, now);
}
