-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Employee" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "nik" TEXT NOT NULL,
    "namaLengkap" TEXT NOT NULL,
    "tempatLahir" TEXT NOT NULL,
    "tanggalLahir" TIMESTAMP(3) NOT NULL,
    "jenisKelamin" TEXT NOT NULL,
    "alamat" TEXT NOT NULL,
    "foto" TEXT,
    "createdById" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Employee_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Pendidikan" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "jenjang" TEXT NOT NULL,
    "namaSekolah" TEXT NOT NULL,
    "tahunMasuk" TEXT NOT NULL,
    "tahunLulus" TEXT,

    CONSTRAINT "Pendidikan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Pekerjaan" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "namaPerusahaan" TEXT NOT NULL,
    "jabatan" TEXT NOT NULL,
    "tahunMasuk" TEXT NOT NULL,
    "tahunKeluar" TEXT,

    CONSTRAINT "Pekerjaan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Keluarga" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "hubungan" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "tanggalLahir" TIMESTAMP(3),

    CONSTRAINT "Keluarga_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Employee_nik_key" ON "Employee"("nik");

-- AddForeignKey
ALTER TABLE "Employee" ADD CONSTRAINT "Employee_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Employee" ADD CONSTRAINT "Employee_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pendidikan" ADD CONSTRAINT "Pendidikan_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "Employee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Pekerjaan" ADD CONSTRAINT "Pekerjaan_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "Employee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Keluarga" ADD CONSTRAINT "Keluarga_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "Employee"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
