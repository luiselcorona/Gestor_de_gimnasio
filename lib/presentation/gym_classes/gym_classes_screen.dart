// ignore_for_file: library_private_types_in_public_api, unnecessary_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:gymy/basedatos_helper.dart';

class GymClassesScreen extends StatefulWidget {
  const GymClassesScreen({super.key});

  @override
  _GymClassesScreenState createState() => _GymClassesScreenState();
}

class _GymClassesScreenState extends State<GymClassesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final List<Map<String, String>> _people = [];
  final List<Map<String, String>> _filteredPeople = [];
  final TextEditingController _searchController = TextEditingController();
  String _nameError = '';

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final people = await _dbHelper.getPeople();
    setState(() {
      _people.clear();
      _filteredPeople.clear();
      for (var person in people) {
        final personData = {
          'id': person['id'].toString(),
          'name': person['name'].toString(),
          'paymentDate': DateFormat('dd-MM-yyyy').format(DateFormat('yyyy-MM-dd').parse(person['paymentDate'].toString())),
          'daysLeft': _calculateDaysLeft(person['paymentDate'].toString()),
        };
        _people.add(personData);
        _filteredPeople.add(personData);
      }
      _sortPeopleByPaymentDateAndName();
    });
  }

  void _addOrUpdatePerson({int? index, required String name, required String paymentDate}) async {
    final existingPerson = _people.firstWhere(
      (person) => person['name'] == name,
      orElse: () => {},
    );

    if (existingPerson.isNotEmpty && index == null) {
      setState(() {
        _nameError = 'Ya existe una persona con este nombre';
      });
      return;
    }

    final id = index == null
        ? await _dbHelper.insertPerson(name, paymentDate, _calculateDaysLeft(paymentDate))
        : int.parse(_filteredPeople[index]['id']!);
    if (index != null) {
      await _dbHelper.updatePerson(id, name, paymentDate, _calculateDaysLeft(paymentDate));
    }
    setState(() {
      final personData = {
        'id': id.toString(),
        'name': name,
        'paymentDate': DateFormat('dd-MM-yyyy').format(DateFormat('yyyy-MM-dd').parse(paymentDate)),
        'daysLeft': _calculateDaysLeft(paymentDate),
      };
      if (index == null) {
        _people.add(personData);
        _filteredPeople.add(personData);
      } else {
        final originalIndex = _people.indexWhere((person) => person['id'] == id.toString());
        _people[originalIndex] = personData;
        _filteredPeople[index] = personData;
      }
      _sortPeopleByPaymentDateAndName();
    });

    if (index != null) {
      Get.back(); // Close the dialog after updating
    }
  }

  void _deletePerson(int index) async {
    final id = int.parse(_filteredPeople[index]['id']!);
    await _dbHelper.deletePerson(id);
    setState(() {
      _people.removeWhere((person) => person['id'] == id.toString());
      _filteredPeople.removeAt(index);
    });
  }

  String _calculateDaysLeft(String paymentDate) {
    final DateTime paymentDateTime = DateFormat('yyyy-MM-dd').parse(paymentDate);
    DateTime nextPaymentDate = DateTime(paymentDateTime.year, paymentDateTime.month, 5);

    if (DateTime.now().isAfter(nextPaymentDate)) {
      nextPaymentDate = DateTime(paymentDateTime.year, paymentDateTime.month + 1, 5);
    }

    final int daysLeft = nextPaymentDate.difference(DateTime.now()).inDays;
    return daysLeft > 0 ? '$daysLeft días' : '0 días';
  }

  void _sortPeopleByPaymentDateAndName() {
    _people.sort((a, b) {
      final DateTime paymentDateA = DateFormat('dd-MM-yyyy').parse(a['paymentDate']!);
      final DateTime paymentDateB = DateFormat('dd-MM-yyyy').parse(b['paymentDate']!);
      if (paymentDateA == paymentDateB) {
        return _compareNames(a['name']!, b['name']!);
      }
      return paymentDateA.compareTo(paymentDateB);
    });
    _filteredPeople.sort((a, b) {
      final DateTime paymentDateA = DateFormat('dd-MM-yyyy').parse(a['paymentDate']!);
      final DateTime paymentDateB = DateFormat('dd-MM-yyyy').parse(b['paymentDate']!);
      if (paymentDateA == paymentDateB) {
        return _compareNames(a['name']!, b['name']!);
      }
      return paymentDateA.compareTo(paymentDateB);
    });
  }

  void _sortPeopleByName() {
    setState(() {
      _people.sort((a, b) => _compareNames(a['name']!, b['name']!));
      _filteredPeople.sort((a, b) => _compareNames(a['name']!, b['name']!));
    });
  }

  int _compareNames(String a, String b) {
    final specialCharPattern = RegExp(r'^[^a-zA-Z0-9]');
    final numberPattern = RegExp(r'^[0-9]');
    if (specialCharPattern.hasMatch(a) && !specialCharPattern.hasMatch(b)) {
      return -1;
    } else if (!specialCharPattern.hasMatch(a) && specialCharPattern.hasMatch(b)) {
      return 1;
    } else if (numberPattern.hasMatch(a) && !numberPattern.hasMatch(b)) {
      return -1;
    } else if (!numberPattern.hasMatch(a) && numberPattern.hasMatch(b)) {
      return 1;
    } else {
      return a.toLowerCase().compareTo(b.toLowerCase());
    }
  }

  void _sortPeopleByDaysLeft() {
    setState(() {
      _people.sort((a, b) {
        final int daysLeftA = int.parse(a['daysLeft']!.split(' ')[0]);
        final int daysLeftB = int.parse(b['daysLeft']!.split(' ')[0]);
        return daysLeftA.compareTo(daysLeftB);
      });
      _filteredPeople.sort((a, b) {
        final int daysLeftA = int.parse(a['daysLeft']!.split(' ')[0]);
        final int daysLeftB = int.parse(b['daysLeft']!.split(' ')[0]);
        return daysLeftA.compareTo(daysLeftB);
      });
    });
  }

  void _showAddPersonDialog({int? index}) {
    final TextEditingController nameController = TextEditingController(text: index != null ? _filteredPeople[index]['name'] : '');
    DateTime selectedDate = index != null ? DateFormat('dd-MM-yyyy').parse(_filteredPeople[index]['paymentDate']!) : DateTime.now();
    final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
    final TextEditingController paymentDateController = TextEditingController(text: dateFormat.format(selectedDate));

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(index == null ? 'Agregar Persona' : 'Actualizar Persona'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    errorText: _nameError.isEmpty ? null : _nameError,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _nameError = '';
                    });
                  },
                ),
                TextField(
                  controller: paymentDateController,
                  decoration: InputDecoration(
                    labelText: 'Día de Pago',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(), // Ensure the date is not in the future
                          locale: const Locale('es', 'ES'), // Set locale to Spanish
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.blue, // header background color
                                  onPrimary: Colors.white, // header text color
                                  onSurface: Colors.black, // body text color
                                ),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            paymentDateController.text = dateFormat.format(selectedDate);
                          });
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (nameController.text.isEmpty || paymentDateController.text.isEmpty) {
                    Get.snackbar('Error', 'Nombre y Día de Pago son obligatorios',
                        snackPosition: SnackPosition.BOTTOM);
                  } else if (_people.any((person) => person['name'] == nameController.text) && index == null) {
                    setState(() {
                      _nameError = 'Ya existe una persona con este nombre';
                    });
                  } else {
                    _addOrUpdatePerson(index: index, name: nameController.text, paymentDate: DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(paymentDateController.text)));
                    nameController.clear();
                    paymentDateController.text = dateFormat.format(DateTime.now());
                    if (index == null) {
                      setState(() {
                        _nameError = '';
                      });
                    }
                  }
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                child: Text(index == null ? 'Agregar' : 'Actualizar'),
              ),
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Salir'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(int index) {
    Get.dialog(
      AlertDialog(
        title: Text('Eliminar Persona'),
        content: Text('¿Estás seguro de que deseas eliminar a esta persona?'),
        actions: [
          TextButton(
            onPressed: () {
              _deletePerson(index);
              Get.back();
            },
            child: Text('Sí'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showPersonOptionsDialog(int index) {
    Get.dialog(
      AlertDialog(
        title: Text('Opciones'),
        content: Text('Seleccione una opción', style: TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _showAddPersonDialog(index: index);
            },
            child: Text('Actualizar'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _showDeleteConfirmationDialog(index);
            },
            child: Text('Eliminar'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Salir'),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptionsDialog(int index) {
    Get.dialog(
      AlertDialog(
        title: Text('Opciones de Pago'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Salir'),
          ),
          TextButton(
            onPressed: () {
              final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
              _addOrUpdatePerson(index: index, name: _filteredPeople[index]['name']!, paymentDate: today); // Close the dialog after updating
              _loadPeople(); // Refresh the table
            },
            child: Text('Pagó'),
          ),
        ],
      ),
    );
  }

  void _filterPeople(String query) {
    setState(() {
      _filteredPeople.clear();
      if (query.isEmpty) {
        _filteredPeople.addAll(_people);
      } else {
        _filteredPeople.addAll(_people.where((person) => person['name']!.toLowerCase().contains(query.toLowerCase())));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        setState(() {
          _filteredPeople.clear();
          _filteredPeople.addAll(_people);
        });
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lista de personas: ${_filteredPeople.length}', style: TextStyle(fontSize: 23, fontWeight: FontWeight.normal)),
          backgroundColor: const Color.fromARGB(255, 154, 186, 233),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: Text('Buscar Persona'),
                    content: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(labelText: 'Nombre'),
                      onChanged: _filterPeople,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          _filterPeople(_searchController.text);
                          Get.back();
                        },
                        child: Text('Buscar'),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterPeople('');
                          Get.back();
                        },
                        child: Text('Cancelar'),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _showAddPersonDialog,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _sortPeopleByName,
                    child: Text('Nombre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: const Color.fromARGB(255, 0, 0, 0))),
                  ),
                  SizedBox(width: 20), // Add space between columns
                  GestureDetector(
                    onTap: _sortPeopleByPaymentDateAndName,
                    child: Text('Día de Pago', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: const Color.fromARGB(255, 0, 0, 0))),
                  ),
                  GestureDetector(
                    onTap: _sortPeopleByDaysLeft,
                    child: Text('Días Faltantes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: const Color.fromARGB(255, 0, 0, 0))),
                  ),
                ],
              ),
              const Divider(thickness: 2, color:  Color.fromARGB(255, 0, 0, 0)),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredPeople.length,
                  itemBuilder: (context, index) {
                    final person = _filteredPeople[index];
                    final int daysLeft = int.parse(person['daysLeft']!.split(' ')[0]);
                    final bool isOverdue = daysLeft < 0;
                    return GestureDetector(
                      onLongPress: () => _showPersonOptionsDialog(index),
                      child: Column(
                        children: [
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 0.0), // Adjust vertical margin
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2.0)),
                            elevation: 6.0,
                            child: Container(
                              width: double.infinity, // Make the card fill the entire row
                              padding: EdgeInsets.symmetric(vertical: 10.0), // Increase row height
                              decoration: BoxDecoration(
                                color: isOverdue ? Colors.red.withOpacity(0.7) : null,
                                gradient: isOverdue
                                    ? null
                                    : RadialGradient(
                                        center: Alignment.center,
                                        radius: 8.5,
                                        colors: [
                                          Colors.white,
                                          Colors.transparent,
                                        ],
                                        stops: [0.5, 1.0],
                                      ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0), // Add horizontal padding
                                      child: Text(
                                        person['name']!,
                                        style: TextStyle(fontSize: 14, color: Colors.black),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20), // Add space between columns
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        person['paymentDate']!,
                                        style: TextStyle(fontSize: 14, color: Colors.black),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: GestureDetector(
                                        onLongPress: () => _showPaymentOptionsDialog(index),
                                        child: Text(
                                          person['daysLeft']!,
                                          style: TextStyle(fontSize: 14, color: Colors.black),
                                          overflow: TextOverflow.visible,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(color: Colors.grey.withOpacity(0.5)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
