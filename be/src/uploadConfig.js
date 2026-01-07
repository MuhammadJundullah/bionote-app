const fs = require("fs");
const path = require("path");
const multer = require("multer");

const uploadsRoot = process.env.VERCEL
  ? "/tmp/uploads"
  : path.join(__dirname, "..", "uploads");

const ensureDir = (dirPath) => {
  fs.mkdirSync(dirPath, { recursive: true });
};

const imageFileFilter = (_req, file, cb) => {
  if (file.mimetype && file.mimetype.startsWith("image/")) {
    cb(null, true);
  } else {
    cb(new Error("Hanya file gambar yang diperbolehkan"));
  }
};

const makeUploader = (subdir) => {
  const targetDir = path.join(uploadsRoot, subdir);
  ensureDir(targetDir);
  const storage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, targetDir),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname || "") || ".jpg";
      const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
      cb(null, `${unique}${ext}`);
    },
  });
  return multer({
    storage,
    fileFilter: imageFileFilter,
    limits: { fileSize: 2 * 1024 * 1024 },
  });
};

const buildPublicPath = (subdir, filename) => `/uploads/${subdir}/${filename}`;

const removeLocalFile = (publicPath) => {
  if (!publicPath || !publicPath.startsWith("/uploads/")) return;
  const relative = publicPath.replace(/^\/uploads\//, "");
  const absolutePath = path.join(uploadsRoot, relative);
  fs.unlink(absolutePath, (err) => {
    if (err && err.code !== "ENOENT") {
      console.warn("Gagal menghapus file lama", err.message);
    }
  });
};

module.exports = {
  uploadsRoot,
  ensureDir,
  makeUploader,
  buildPublicPath,
  removeLocalFile,
};
