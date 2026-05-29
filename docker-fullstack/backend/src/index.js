import express from "express";

const app = express();
const PORT = process.env.BACKEND_PORT || 4000;

app.get("/", (req, res) => {
  res.json({ message: "Backend running" });
});

app.get("/api/health", (req, res) => {
  res.json({ status: "ok" });
});

app.listen(PORT, () => {
  console.log(`Backend running on port ${PORT}`);
});
