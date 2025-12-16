const express = require("express");
const prisma = require("../prismaClient");

const router = express.Router();

const employeeIncludes = {
  user: true,
  createdBy: true,
  pendidikan: true,
  pekerjaan: true,
  keluarga: true,
};

router.get("/", async (_req, res) => {
  try {
    const employees = await prisma.employee.findMany({
      orderBy: { createdAt: "desc" },
      include: employeeIncludes,
    });
    return res.json(employees);
  } catch (error) {
    console.error("Get employees error", error);
    return res.status(500).json({ message: "Gagal mengambil data karyawan" });
  }
});

router.get("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    const employee = await prisma.employee.findUnique({
      where: { id },
      include: employeeIncludes,
    });
    if (!employee) {
      return res.status(404).json({ message: "Karyawan tidak ditemukan" });
    }
    return res.json(employee);
  } catch (error) {
    console.error("Get employee error", error);
    return res.status(500).json({ message: "Gagal mengambil data karyawan" });
  }
});

router.post("/", async (req, res) => {
  const {
    userId,
    nik,
    namaLengkap,
    tempatLahir,
    tanggalLahir,
    jenisKelamin,
    alamat,
    foto,
    createdById,
  } = req.body;

  if (!nik || !namaLengkap || !tempatLahir || !tanggalLahir || !jenisKelamin || !alamat || !createdById) {
    return res.status(400).json({ message: "Field wajib belum lengkap" });
  }

  const parsedTanggalLahir = new Date(tanggalLahir);
  if (Number.isNaN(parsedTanggalLahir.getTime())) {
    return res.status(400).json({ message: "Format tanggal_lahir tidak valid" });
  }

  try {
    const creator = await prisma.user.findUnique({ where: { id: createdById } });
    if (!creator) {
      return res.status(400).json({ message: "createdById tidak valid" });
    }

    if (userId) {
      const linkedUser = await prisma.user.findUnique({ where: { id: userId } });
      if (!linkedUser) {
        return res.status(400).json({ message: "userId tidak valid" });
      }
    }

    const employee = await prisma.employee.create({
      data: {
        userId: userId || null,
        nik,
        namaLengkap,
        tempatLahir,
        tanggalLahir: parsedTanggalLahir,
        jenisKelamin,
        alamat,
        foto: foto || null,
        createdById,
      },
      include: employeeIncludes,
    });

    return res.status(201).json(employee);
  } catch (error) {
    if (error.code === "P2002") {
      return res.status(400).json({ message: "NIK sudah terpakai" });
    }
    console.error("Create employee error", error);
    return res.status(500).json({ message: "Gagal membuat karyawan" });
  }
});

router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const {
    userId,
    nik,
    namaLengkap,
    tempatLahir,
    tanggalLahir,
    jenisKelamin,
    alamat,
    foto,
    createdById,
  } = req.body;

  const data = {};
  if (userId !== undefined) data.userId = userId;
  if (nik) data.nik = nik;
  if (namaLengkap) data.namaLengkap = namaLengkap;
  if (tempatLahir) data.tempatLahir = tempatLahir;
  if (tanggalLahir) {
    const parsed = new Date(tanggalLahir);
    if (Number.isNaN(parsed.getTime())) {
      return res.status(400).json({ message: "Format tanggal_lahir tidak valid" });
    }
    data.tanggalLahir = parsed;
  }
  if (jenisKelamin) data.jenisKelamin = jenisKelamin;
  if (alamat) data.alamat = alamat;
  if (foto !== undefined) data.foto = foto;
  if (createdById) data.createdById = createdById;

  try {
    const employee = await prisma.employee.update({
      where: { id },
      data,
      include: employeeIncludes,
    });
    return res.json(employee);
  } catch (error) {
    if (error.code === "P2025") {
      return res.status(404).json({ message: "Karyawan tidak ditemukan" });
    }
    if (error.code === "P2002") {
      return res.status(400).json({ message: "NIK sudah terpakai" });
    }
    console.error("Update employee error", error);
    return res.status(500).json({ message: "Gagal memperbarui karyawan" });
  }
});

router.delete("/:id", async (req, res) => {
  const { id } = req.params;
  try {
    await prisma.employee.delete({ where: { id } });
    return res.status(204).send();
  } catch (error) {
    if (error.code === "P2025") {
      return res.status(404).json({ message: "Karyawan tidak ditemukan" });
    }
    console.error("Delete employee error", error);
    return res.status(500).json({ message: "Gagal menghapus karyawan" });
  }
});

// Pendidikan
router.post("/:employeeId/pendidikan", async (req, res) => {
  const { employeeId } = req.params;
  const { jenjang, namaSekolah, tahunMasuk, tahunLulus } = req.body;

  if (!jenjang || !namaSekolah || !tahunMasuk) {
    return res.status(400).json({ message: "Jenjang, nama_sekolah, tahun_masuk wajib diisi" });
  }

  try {
    const employee = await prisma.employee.findUnique({ where: { id: employeeId } });
    if (!employee) {
      return res.status(404).json({ message: "Karyawan tidak ditemukan" });
    }

    const pendidikan = await prisma.pendidikan.create({
      data: { employeeId, jenjang, namaSekolah, tahunMasuk, tahunLulus: tahunLulus || null },
    });
    return res.status(201).json(pendidikan);
  } catch (error) {
    console.error("Create pendidikan error", error);
    return res.status(500).json({ message: "Gagal menambah pendidikan" });
  }
});

router.put("/:employeeId/pendidikan/:id", async (req, res) => {
  const { employeeId, id } = req.params;
  const { jenjang, namaSekolah, tahunMasuk, tahunLulus } = req.body;

  try {
    const existing = await prisma.pendidikan.findFirst({ where: { id, employeeId } });
    if (!existing) {
      return res.status(404).json({ message: "Data pendidikan tidak ditemukan" });
    }

    const pendidikan = await prisma.pendidikan.update({
      where: { id },
      data: {
        jenjang: jenjang || existing.jenjang,
        namaSekolah: namaSekolah || existing.namaSekolah,
        tahunMasuk: tahunMasuk || existing.tahunMasuk,
        tahunLulus: tahunLulus !== undefined ? tahunLulus : existing.tahunLulus,
      },
    });
    return res.json(pendidikan);
  } catch (error) {
    console.error("Update pendidikan error", error);
    return res.status(500).json({ message: "Gagal memperbarui pendidikan" });
  }
});

router.delete("/:employeeId/pendidikan/:id", async (req, res) => {
  const { employeeId, id } = req.params;
  try {
    const existing = await prisma.pendidikan.findFirst({ where: { id, employeeId } });
    if (!existing) {
      return res.status(404).json({ message: "Data pendidikan tidak ditemukan" });
    }
    await prisma.pendidikan.delete({ where: { id } });
    return res.status(204).send();
  } catch (error) {
    console.error("Delete pendidikan error", error);
    return res.status(500).json({ message: "Gagal menghapus pendidikan" });
  }
});

// Pekerjaan
router.post("/:employeeId/pekerjaan", async (req, res) => {
  const { employeeId } = req.params;
  const { namaPerusahaan, jabatan, tahunMasuk, tahunKeluar } = req.body;

  if (!namaPerusahaan || !jabatan || !tahunMasuk) {
    return res.status(400).json({ message: "Nama perusahaan, jabatan, tahun_masuk wajib diisi" });
  }

  try {
    const employee = await prisma.employee.findUnique({ where: { id: employeeId } });
    if (!employee) {
      return res.status(404).json({ message: "Karyawan tidak ditemukan" });
    }

    const pekerjaan = await prisma.pekerjaan.create({
      data: { employeeId, namaPerusahaan, jabatan, tahunMasuk, tahunKeluar: tahunKeluar || null },
    });
    return res.status(201).json(pekerjaan);
  } catch (error) {
    console.error("Create pekerjaan error", error);
    return res.status(500).json({ message: "Gagal menambah riwayat pekerjaan" });
  }
});

router.put("/:employeeId/pekerjaan/:id", async (req, res) => {
  const { employeeId, id } = req.params;
  const { namaPerusahaan, jabatan, tahunMasuk, tahunKeluar } = req.body;

  try {
    const existing = await prisma.pekerjaan.findFirst({ where: { id, employeeId } });
    if (!existing) {
      return res.status(404).json({ message: "Data pekerjaan tidak ditemukan" });
    }

    const pekerjaan = await prisma.pekerjaan.update({
      where: { id },
      data: {
        namaPerusahaan: namaPerusahaan || existing.namaPerusahaan,
        jabatan: jabatan || existing.jabatan,
        tahunMasuk: tahunMasuk || existing.tahunMasuk,
        tahunKeluar: tahunKeluar !== undefined ? tahunKeluar : existing.tahunKeluar,
      },
    });
    return res.json(pekerjaan);
  } catch (error) {
    console.error("Update pekerjaan error", error);
    return res.status(500).json({ message: "Gagal memperbarui pekerjaan" });
  }
});

router.delete("/:employeeId/pekerjaan/:id", async (req, res) => {
  const { employeeId, id } = req.params;
  try {
    const existing = await prisma.pekerjaan.findFirst({ where: { id, employeeId } });
    if (!existing) {
      return res.status(404).json({ message: "Data pekerjaan tidak ditemukan" });
    }
    await prisma.pekerjaan.delete({ where: { id } });
    return res.status(204).send();
  } catch (error) {
    console.error("Delete pekerjaan error", error);
    return res.status(500).json({ message: "Gagal menghapus pekerjaan" });
  }
});

// Keluarga
router.post("/:employeeId/keluarga", async (req, res) => {
  const { employeeId } = req.params;
  const { hubungan, nama, tanggalLahir } = req.body;

  if (!hubungan || !nama) {
    return res.status(400).json({ message: "Hubungan dan nama wajib diisi" });
  }

  let tanggalLahirDate = null;
  if (tanggalLahir) {
    const parsed = new Date(tanggalLahir);
    if (Number.isNaN(parsed.getTime())) {
      return res.status(400).json({ message: "Format tanggal_lahir tidak valid" });
    }
    tanggalLahirDate = parsed;
  }

  try {
    const employee = await prisma.employee.findUnique({ where: { id: employeeId } });
    if (!employee) {
      return res.status(404).json({ message: "Karyawan tidak ditemukan" });
    }

    const keluarga = await prisma.keluarga.create({
      data: { employeeId, hubungan, nama, tanggalLahir: tanggalLahirDate },
    });
    return res.status(201).json(keluarga);
  } catch (error) {
    console.error("Create keluarga error", error);
    return res.status(500).json({ message: "Gagal menambah data keluarga" });
  }
});

router.put("/:employeeId/keluarga/:id", async (req, res) => {
  const { employeeId, id } = req.params;
  const { hubungan, nama, tanggalLahir } = req.body;

  let tanggalLahirDate = undefined;
  if (tanggalLahir !== undefined) {
    const parsed = new Date(tanggalLahir);
    if (Number.isNaN(parsed.getTime())) {
      return res.status(400).json({ message: "Format tanggal_lahir tidak valid" });
    }
    tanggalLahirDate = parsed;
  }

  try {
    const existing = await prisma.keluarga.findFirst({ where: { id, employeeId } });
    if (!existing) {
      return res.status(404).json({ message: "Data keluarga tidak ditemukan" });
    }

    const keluarga = await prisma.keluarga.update({
      where: { id },
      data: {
        hubungan: hubungan || existing.hubungan,
        nama: nama || existing.nama,
        tanggalLahir: tanggalLahirDate !== undefined ? tanggalLahirDate : existing.tanggalLahir,
      },
    });
    return res.json(keluarga);
  } catch (error) {
    console.error("Update keluarga error", error);
    return res.status(500).json({ message: "Gagal memperbarui data keluarga" });
  }
});

router.delete("/:employeeId/keluarga/:id", async (req, res) => {
  const { employeeId, id } = req.params;
  try {
    const existing = await prisma.keluarga.findFirst({ where: { id, employeeId } });
    if (!existing) {
      return res.status(404).json({ message: "Data keluarga tidak ditemukan" });
    }
    await prisma.keluarga.delete({ where: { id } });
    return res.status(204).send();
  } catch (error) {
    console.error("Delete keluarga error", error);
    return res.status(500).json({ message: "Gagal menghapus data keluarga" });
  }
});

module.exports = router;
