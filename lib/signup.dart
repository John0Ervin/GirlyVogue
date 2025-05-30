import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';


class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _otpController = TextEditingController();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _houseNumberController = TextEditingController();
  TextEditingController _streetController = TextEditingController();
  TextEditingController _birthdayController = TextEditingController();
  TextEditingController _provinceController = TextEditingController();
  TextEditingController _municipalityController = TextEditingController();
  TextEditingController _barangayController = TextEditingController();
  bool _agreeToTerms = false;
  

  // Sample data for dropdowns
List<String> provinces = [
  'Ilocos Norte', 'Ilocos Sur', 'Metro Manila', 'Cavite', 'Laguna', 
  'Rizal', 'Batangas', 'Pampanga', 'Benguet'
];

// City/Municipality dropdown will update based on the selected province
List<String> municipalities = []; // This will be dynamically updated based on the province

// Barangay dropdown will update based on the selected city/municipality
List<String> barangays = []; // This will be dynamically updated based on the selected city

// Sample logic to dynamically update the dropdowns when a province is selected
void updateMunicipalities(String province) {
  switch (province) {
    case 'Ilocos Norte':
      municipalities = ['Laoag City', 'Batac City'];
      break;
    case 'Ilocos Sur':
      municipalities = ['Vigan City', 'Candon City'];
      break;
    case 'Metro Manila':
      municipalities = ['Quezon City', 'Manila'];
      break;
    case 'Cavite':
      municipalities = ['Tagaytay City', 'Dasmariñas'];
      break;
    case 'Laguna':
      municipalities = [
        'Biñan City', 'Cabuyao City', 'Calamba City', 'Santa Rosa City',
        'San Pedro City', 'Los Baños', 'Bay', 'Santa Cruz', 'San Pablo City', 
        'Pagsanjan', 'Liliw', 'Lumban'
      ];
      break;
    case 'Rizal':
      municipalities = ['Antipolo City', 'Cainta'];
      break;
    case 'Batangas':
      municipalities = ['Lipa City', 'Batangas City'];
      break;
    case 'Pampanga':
      municipalities = ['Angeles City', 'San Fernando'];
      break;
    case 'Benguet':
      municipalities = ['Baguio City', 'La Trinidad'];
      break;
  }
}

void updateBarangays(String municipalities) {
  switch (municipalities) {
    case 'Biñan City':
      barangays = [
        'Barangay Biñan', 'Barangay Canlalay', 'Barangay De La Paz', 
        'Barangay Langkiwa', 'Barangay Malaban', 'Barangay Platero', 
        'Barangay San Antonio', 'Barangay San Francisco', 'Barangay Santo Tomas', 
        'Barangay Timbao'
      ];
      break;
    case 'Cabuyao City':
      barangays = [
        'Barangay Banay-Banay', 'Barangay Baclaran', 'Barangay Bigaa', 
        'Barangay Gulod', 'Barangay Mamatid', 'Barangay Marinig', 
        'Barangay Niugan', 'Barangay Pulo', 'Barangay Sala', 'Barangay Uwisan'
      ];
      break;
    case 'Calamba City':
      barangays = [
        'Barangay Bagong Kalsada', 'Barangay Banadero', 'Barangay Bucal', 
        'Barangay Halang', 'Barangay Lecheria', 'Barangay Lawa', 'Barangay Mayapa', 
        'Barangay Real', 'Barangay Saimsim', 'Barangay Tulo', 'Barangay Pansol'
      ];
      break;
    case 'Santa Rosa City':
      barangays = [
        'Barangay Aplaya', 'Barangay Balibago', 'Barangay Dila', 'Barangay Don Jose', 
        'Barangay Macabling', 'Barangay Malitlit', 'Barangay Sinalhan', 'Barangay Tagapo', 
        'Barangay Pulong Santa Cruz', 'Barangay Labas'
      ];
      break;
    case 'San Pedro City':
      barangays = [
        'Barangay San Vicente', 'Barangay Landayan', 'Barangay San Antonio', 
        'Barangay Cuyab', 'Barangay Riverside', 'Barangay Sampaguita', 
        'Barangay Pacita 1', 'Barangay Pacita 2', 'Barangay United Bayanihan', 
        'Barangay Fatima'
      ];
      break;
    case 'Los Baños':
      barangays = [
        'Barangay Anos', 'Barangay Bagong Silang', 'Barangay Bayog', 'Barangay Lalakay', 
        'Barangay Maahas', 'Barangay Mayondon', 'Barangay Putho-Tuntungin', 
        'Barangay Tadlac', 'Barangay Timugan'
      ];
      break;
    case 'Bay':
      barangays = [
        'Barangay Bitin', 'Barangay Calo', 'Barangay Dila', 'Barangay Masaya', 
        'Barangay Paciano Rizal', 'Barangay San Antonio', 'Barangay San Isidro', 
        'Barangay Tagumpay', 'Barangay Tranca', 'Barangay Maitim'
      ];
      break;
    case 'Santa Cruz':
      barangays = [
        'Barangay Alipit', 'Barangay Bagumbayan', 'Barangay Bubukal', 'Barangay Calios', 
        'Barangay Malinao', 'Barangay Pagsawitan', 'Barangay Patimbao', 'Barangay Poblacion', 
        'Barangay San Jose', 'Barangay San Pablo Norte'
      ];
      break;
    case 'San Pablo City':
      barangays = [
        'Barangay Atisan', 'Barangay Bagong Pook', 'Barangay San Jose', 'Barangay San Lucas', 
        'Barangay San Rafael', 'Barangay San Roque', 'Barangay San Vicente', 
        'Barangay Santa Catalina', 'Barangay Del Remedio', 'Barangay Santiago'
      ];
      break;
    case 'Pagsanjan':
      barangays = [
        'Barangay Anibong', 'Barangay Biñan', 'Barangay Calusiche', 'Barangay Dingin', 
        'Barangay Lambac', 'Barangay Maulawin', 'Barangay Pinagsanjan', 'Barangay Sabang', 
        'Barangay Sampaloc', 'Barangay Santa Cruz'
      ];
      break;
    case 'Liliw':
      barangays = [
        'Barangay Bagong Silang', 'Barangay Dita', 'Barangay Ilayang Sungi', 
        'Barangay Ibabang Sungi', 'Barangay Kanluran', 'Barangay Malabo', 
        'Barangay Masikap', 'Barangay Pag-Asa', 'Barangay San Roque', 'Barangay Taytay'
      ];
      break;
    case 'Lumban':
      barangays = [
        'Barangay Balimbingan', 'Barangay Bagong Silang', 'Barangay Balubad', 
        'Barangay Cabanbanan', 'Barangay Concepcion', 'Barangay Duhat', 'Barangay Gagalot', 
        'Barangay Lewin', 'Barangay Maracta', 'Barangay Maytalang 1', 'Barangay Maytalang 2', 
        'Barangay Primera Parang', 'Barangay Primera Pulo', 'Barangay Salac', 
        'Barangay Segunda Parang', 'Barangay Segunda Pulo', 'Barangay Wawa'
      ];
      break;
    // Handle other cities in Laguna similarly
  }
}


  String? selectedProvince;
  String? selectedMunicipality;
  
  String? selectedBarangay;

   void _requestOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email to get OTP')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/api/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': email,
        'password': _passwordController.text.trim(),
        'birthday': _birthdayController.text.trim(),
        'house_number': _houseNumberController.text.trim(),
        'street': _streetController.text.trim(),
        'province': selectedProvince ?? '',
        'municipality': selectedMunicipality ?? '',
        'barangay': selectedBarangay ?? '',
        'agree_to_terms': _agreeToTerms ? 'true' : 'false',
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent to $email')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create a New Account - GirlyVogue'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                  context,
                    MaterialPageRoute(
                      builder: (context) => LoginPage(),
                    ),
              );
            },
            child: Text('LOGIN', style: TextStyle(color: const Color.fromARGB(255, 85, 120, 215))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Name Section
                TextFormField(
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'First Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'Last Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),

                // Email Section
                TextFormField(
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                // Password Section
                TextFormField(
                  controller: _passwordController, // <-- Add this
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),

                // OTP Section
                TextFormField(
                  controller: _otpController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'Enter OTP'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the OTP';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: _requestOTP,
                  child: Text('Get OTP'),
                ),

                // Birthday Section
                TextFormField(
                  controller: _birthdayController,
                  decoration: InputDecoration(labelText: 'Birthday'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your birthday';
                    }
                    return null;
                  },
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode()); // Hide the keyboard
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _birthdayController.text = '${pickedDate.toLocal()}'.split(' ')[0];
                      });
                    }
                  },
                ),

                // Address Section (House Number, Street)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _houseNumberController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'House Number'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _streetController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'Street Name'),
                      ),
                    ),
                  ],
                ),

                // Province Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Province'),
                  value: selectedProvince,
                  items: provinces.map((String province) {
                    return DropdownMenuItem<String>(
                      value: province,
                      child: Text(province),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProvince = value;
                      selectedMunicipality = null;
                      selectedBarangay = null;
                      municipalities = [];
                      barangays = [];
                      updateMunicipalities(value!);
                    });
                  },
                  validator: (value) => value == null ? 'Please select a province' : null,
                ),

                // Municipality/City Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Municipality / City'),
                  value: selectedMunicipality,
                  items: municipalities.map((String muni) {
                    return DropdownMenuItem<String>(
                      value: muni,
                      child: Text(muni),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMunicipality = value;
                      selectedBarangay = null;
                      barangays = [];
                      updateBarangays(value!);
                    });
                  },
                  validator: (value) => value == null ? 'Please select a municipality/city' : null,
                ),

                // Barangay Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Barangay'),
                  value: selectedBarangay,
                  items: barangays.map((String brgy) {
                    return DropdownMenuItem<String>(
                      value: brgy,
                      child: Text(brgy),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBarangay = value;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a barangay' : null,
                ),

                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                    ),
                    Text('I agree to the terms and conditions'),
                  ],
                ),

                ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    if (_agreeToTerms) {
                      // Send data to Flask backend
                      final response = await http.post(
                        Uri.parse('http://10.0.2.2:5000/api/signup'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'first_name': _firstNameController.text.trim(),
                          'last_name': _lastNameController.text.trim(),
                          'email': _emailController.text.trim(),
                          'password': _passwordController.text.trim(),
                          'birthday': _birthdayController.text.trim(),
                          'house_number': _houseNumberController.text.trim(),
                          'street': _streetController.text.trim(),
                          'province': selectedProvince ?? '',
                          'municipality': selectedMunicipality ?? '',
                          'barangay': selectedBarangay ?? '',
                          'agree_to_terms': _agreeToTerms ? 'true' : 'false',
                        }),
                      );

                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registration successful!')),
                        );
                        Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Registration failed: ${response.body}')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('You must agree to the terms and conditions')),
                      );
                    }
                  }
                },
                child: Text('Register'),
              ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}