import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import 'login.dart';

class ProfileScreen extends StatefulWidget {
  final String fullName;
  final String email;

  const ProfileScreen({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  Uint8List? _profileImageBytes;

  String _fullName = '';
  String _email = '';
  String _phone = 'Not set';
  String _address = 'Not set';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          _fullName = widget.fullName;
          _email = widget.email;
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        Uint8List? loadedImageBytes;

        final profileImageBase64 = data['profileImageBase64'];

        if (profileImageBase64 != null &&
            profileImageBase64 is String &&
            profileImageBase64.isNotEmpty) {
          try {
            loadedImageBytes = base64Decode(profileImageBase64);
          } catch (_) {
            loadedImageBytes = null;
          }
        }

        if (!mounted) return;

        setState(() {
          _fullName = data['fullName'] ?? widget.fullName;
          _email = data['email'] ?? widget.email;
          _phone = data['phone'] ?? 'Not set';
          _address = data['address'] ?? 'Not set';
          _profileImageBytes = loadedImageBytes;
          _isLoading = false;
        });
      } else {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': widget.fullName,
          'email': widget.email,
          'phone': 'Not set',
          'address': 'Not set',
          'profileImageBase64': '',
        });

        if (!mounted) return;

        setState(() {
          _fullName = widget.fullName;
          _email = widget.email;
          _phone = 'Not set';
          _address = 'Not set';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _fullName = widget.fullName;
        _email = widget.email;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Please login first.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final picker = ImagePicker();

      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      setState(() {
        _isUploadingPhoto = true;
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': _fullName.isEmpty ? widget.fullName : _fullName,
        'email': _email.isEmpty ? widget.email : _email,
        'phone': _phone,
        'address': _address,
        'profileImageBase64': imageBase64,
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _profileImageBytes = bytes;
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profile photo updated!',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update photo: $e',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        ),
      );
    }
  }

  void _openEditProfile() {
    final nameController = TextEditingController(text: _fullName);
    final phoneController = TextEditingController(
      text: _phone == 'Not set' ? '' : _phone,
    );
    final addressController = TextEditingController(
      text: _address == 'Not set' ? '' : _address,
    );

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sheetLabel('Full Name'),
                    const SizedBox(height: 8),
                    _sheetTextField(
                      controller: nameController,
                      hint: 'Enter your full name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _sheetLabel('Phone Number'),
                    const SizedBox(height: 8),
                    _sheetTextField(
                      controller: phoneController,
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _sheetLabel('Address'),
                    const SizedBox(height: 8),
                    _sheetTextField(
                      controller: addressController,
                      hint: 'Enter your address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                          setSheetState(() {
                            isSaving = true;
                          });

                          try {
                            final user =
                                FirebaseAuth.instance.currentUser;

                            if (user == null) {
                              throw Exception('User not logged in.');
                            }

                            final updatedName =
                            nameController.text.trim().isEmpty
                                ? widget.fullName
                                : nameController.text.trim();

                            final updatedPhone =
                            phoneController.text.trim().isEmpty
                                ? 'Not set'
                                : phoneController.text.trim();

                            final updatedAddress =
                            addressController.text.trim().isEmpty
                                ? 'Not set'
                                : addressController.text.trim();

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                              'fullName': updatedName,
                              'email': _email.isEmpty
                                  ? widget.email
                                  : _email,
                              'phone': updatedPhone,
                              'address': updatedAddress,
                            }, SetOptions(merge: true));

                            if (!mounted) return;

                            setState(() {
                              _fullName = updatedName;
                              _phone = updatedPhone;
                              _address = updatedAddress;
                            });

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Profile updated successfully!',
                                  style:
                                  TextStyle(fontFamily: 'Poppins'),
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to update: $e',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                backgroundColor: Colors.red.shade400,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                              ),
                            );
                          } finally {
                            setSheetState(() {
                              isSaving = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isSaving
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          width: 95,
          height: 95,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipOval(
            child: _profileImageBytes != null
                ? Image.memory(
              _profileImageBytes!,
              fit: BoxFit.cover,
              width: 95,
              height: 95,
            )
                : Container(
              color: Colors.green.shade100,
              child: const Icon(
                Icons.person,
                size: 55,
                color: Colors.green,
              ),
            ),
          ),
        ),
        if (_isUploadingPhoto)
          Positioned.fill(
            child: Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploadingPhoto ? null : _pickImage,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.shade300,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.green,
        ),
      )
          : SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF66BB6A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  40,
                ),
                child: Column(
                  children: [
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileAvatar(),
                    const SizedBox(height: 12),
                    Text(
                      _fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoTile(
                        icon: Icons.person_outline,
                        label: 'Full Name',
                        value: _fullName,
                      ),
                      _divider(),
                      _infoTile(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: _email,
                      ),
                      _divider(),
                      _infoTile(
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        value: _phone,
                      ),
                      _divider(),
                      _infoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: _address,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _menuTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: _openEditProfile,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(
                        color: Colors.red,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.green,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
          fontFamily: 'Poppins',
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.green,
          size: 20,
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade100,
    );
  }

  Widget _sheetLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _sheetTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontFamily: 'Poppins',
          fontSize: 13,
        ),
        prefixIcon: maxLines == 1
            ? Icon(
          icon,
          color: Colors.green,
          size: 20,
        )
            : null,
        filled: true,
        fillColor: Colors.green.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.green.shade100,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.green,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}