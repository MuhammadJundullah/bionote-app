const express = require("express");
const authRoutes = require("./auth");
const userRoutes = require("./users");
const employeeRoutes = require("./employees");

const router = express.Router();

router.use("/auth", authRoutes);
router.use("/users", userRoutes);
router.use("/employees", employeeRoutes);

module.exports = router;
