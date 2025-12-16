require("dotenv").config();
const express = require("express");
const cors = require("cors");
const routes = require("./routes");
const prisma = require("./prismaClient");

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.use("/", routes);

app.use((err, _req, res, _next) => {
  console.error("Unhandled error", err);
  res.status(500).json({ message: "Terjadi kesalahan pada server" });
});

const server = app.listen(port, () => {
  console.log(`API running on port ${port}`);
});

process.on("SIGTERM", async () => {
  await prisma.$disconnect();
  server.close(() => process.exit(0));
});

process.on("SIGINT", async () => {
  await prisma.$disconnect();
  server.close(() => process.exit(0));
});
