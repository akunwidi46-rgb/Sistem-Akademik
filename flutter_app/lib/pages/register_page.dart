import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ==========================
  // BASE URL
  // ==========================
  static const String baseUrl = "http://192.168.43.167/flutter_api/";

  // ==========================
  // CONTROLLER
  // ==========================
  final TextEditingController nama = TextEditingController();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  // ==========================
  // VARIABLE
  // ==========================
  bool apiConnected = false;
  bool isLoading = false;
  Timer? timer;

  // ==========================
  // CLEAR FORM
  // ==========================
  void clearRegister() {
    nama.clear();
    username.clear();
    password.clear();
  }

  // ==========================
  // CEK STATUS API
  // ==========================
  Future<bool> checkStatusApi() async {
    try {
      final response = await http.get(Uri.parse("${baseUrl}cek_koneksi.php"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        bool status = data["status"] == true;
        if (mounted) {
          setState(() {
            apiConnected = status;
          });
        }
        return status;
      }
      if (mounted) {
        setState(() {
          apiConnected = false;
        });
      }
      return false;
    } catch (e) {
      if (mounted) {
        setState(() {
          apiConnected = false;
        });
      }
      return false;
    }
  }

  // ==========================
  // REGISTER
  // ==========================
  Future register() async {
    // VALIDASI
    if (nama.text.trim().isEmpty ||
        username.text.trim().isEmpty ||
        password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua data wajib diisi"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // CEK API
    bool apiAktif = await checkStatusApi();
    if (!mounted) return;

    if (!apiAktif) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Koneksi API Terputus"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("${baseUrl}register.php"),
        body: {
          "nama": nama.text.trim(),
          "username": username.text.trim(),
          "password": password.text.trim(),
          "role": "mahasiswa",
        },
      );
      final responseBody = response.body.trim();
      if (!responseBody.startsWith("{")) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Server mengirim response bukan JSON. Cek register.php"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = jsonDecode(responseBody);
      if (!mounted) return;

      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registrasi Berhasil"),
            backgroundColor: Colors.green,
          ),
        );
        clearRegister();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Registrasi Gagal"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error : $e"), backgroundColor: Colors.red),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ==========================
  // INIT STATE
  // ==========================
  @override
  void initState() {
    super.initState();
    checkStatusApi();
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkStatusApi();
    });
  }

  // ==========================
  // DISPOSE
  // ==========================
  @override
  void dispose() {
    timer?.cancel();
    nama.dispose();
    username.dispose();
    password.dispose();
    super.dispose();
  }

  // ==========================
  // UI
  // ==========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo, Colors.blue],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 15,
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_add,
                      size: 80,
                      color: Colors.indigo,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "REGISTER",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 15,
                          color: apiConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 5),
                        Text(apiConnected ? "API Online" : "API Offline"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nama,
                      decoration: const InputDecoration(
                        labelText: "Nama",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: username,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.account_circle),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : register,
                        icon: const Icon(Icons.save),
                        label: isLoading
                            ? const Text("MEMPROSES...")
                            : const Text("REGISTER"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        clearRegister();
                        Navigator.pop(context);
                      },
                      child: const Text("Kembali ke Login"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
