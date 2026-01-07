const express = require("express");
const bcrypt = require("bcrypt");
const prisma = require("../prismaClient");
const { makeUploader, buildPublicPath, removeLocalFile } = require("../uploadConfig");

const router = express.Router();
const uploadUserPhoto = makeUploader("users");

router.get("/", async (_req, res) => {
  try {
    const users = await prisma.user.findMany({
      orderBy: { createdAt: "desc" },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        foto: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    return res.json(users);
  } catch (error) {
    console.error("Get users error", error);
    return res.status(500).json({ message: "Gagal mengambil data users" });
  }
});

router.get("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        foto: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    if (!user) {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }
    return res.json(user);
  } catch (error) {
    console.error("Get user error", error);
    return res.status(500).json({ message: "Gagal mengambil data user" });
  }
});

router.post("/", async (req, res) => {
  const { name, email, password, role } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ message: "Name, email, password wajib diisi" });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: {
        name,
        email,
        password: hashedPassword,
        role: role || "user",
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        foto: true,
        createdAt: true,
        updatedAt: true,
      },
    });
    return res.status(201).json(user);
  } catch (error) {
    if (error.code === "P2002") {
      return res.status(400).json({ message: "Email sudah terpakai" });
    }
    console.error("Create user error", error);
    return res.status(500).json({ message: "Gagal membuat user" });
  }
});

router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const { name, email, password, role } = req.body;

  try {
    const data = {};
    if (name) data.name = name;
    if (email) data.email = email;
    if (role) data.role = role;
    if (password) {
      data.password = await bcrypt.hash(password, 10);
    }

    const user = await prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        foto: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    return res.json(user);
  } catch (error) {
    if (error.code === "P2025") {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }
    if (error.code === "P2002") {
      return res.status(400).json({ message: "Email sudah terpakai" });
    }
    console.error("Update user error", error);
    return res.status(500).json({ message: "Gagal memperbarui user" });
  }
});

router.delete("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    await prisma.user.delete({ where: { id } });
    return res.status(204).send();
  } catch (error) {
    if (error.code === "P2025") {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }
    console.error("Delete user error", error);
    return res.status(500).json({ message: "Gagal menghapus user" });
  }
});

router.post("/:id/photo", uploadUserPhoto.single("foto"), async (req, res) => {
  const { id } = req.params;
  const requesterId = req.header("x-user-id");

  if (!requesterId || requesterId !== id) {
    return res.status(403).json({ message: "Tidak boleh mengubah foto user lain" });
  }

  if (!req.file) {
    return res.status(400).json({ message: "File foto wajib diupload" });
  }

  try {
    const existing = await prisma.user.findUnique({ where: { id } });
    if (!existing) {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }

    const newPhotoPath = buildPublicPath("users", req.file.filename);
    const user = await prisma.user.update({
      where: { id },
      data: { foto: newPhotoPath },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        foto: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    if (existing.foto && existing.foto.startsWith("/uploads/")) {
      removeLocalFile(existing.foto);
    }

    return res.json(user);
  } catch (error) {
    console.error("Upload user photo error", error);
    return res.status(500).json({ message: "Gagal mengupload foto user" });
  }
});

module.exports = router;
