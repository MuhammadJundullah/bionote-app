const express = require("express");
const bcrypt = require("bcrypt");
const prisma = require("../prismaClient");

const router = express.Router();

// Registrasi user baru (tanpa otentikasi admin)
router.post("/register", async (req, res) => {
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
      select: { id: true, name: true, email: true, role: true, createdAt: true },
    });
    return res.status(201).json(user);
  } catch (error) {
    if (error.code === "P2002") {
      return res.status(400).json({ message: "Email sudah terpakai" });
    }
    console.error("Register error", error);
    return res.status(500).json({ message: "Gagal registrasi" });
  }
});

router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: "Email dan password wajib diisi" });
  }

  try {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      return res.status(401).json({ message: "Email atau password salah" });
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ message: "Email atau password salah" });
    }

    // Token/JWT bisa ditambahkan di sini sesuai kebutuhan autentikasi
    return res.json({
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    });
  } catch (error) {
    console.error("Login error", error);
    return res.status(500).json({ message: "Gagal login" });
  }
});

module.exports = router;
