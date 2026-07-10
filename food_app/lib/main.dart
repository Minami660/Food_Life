import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'http://10.0.2.2:54321', // Android emulator
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final foodNameController = TextEditingController();
  final foodAmountController = TextEditingController();
  List<Map<String, dynamic>> foodList = [];
  DateTime? selectedDate;
  String? selectedCategory;
  String? selectedUnit;
  String? unitError;
  bool dateError = false;
  final foodNotecontroller = TextEditingController();

  @override
  void initState() {
    super.initState();
    getFood();
  }

  Future<DateTime?> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
    );
    return pickedDate;
  }

  Future<void> addFood() async {
    final supabase = Supabase.instance.client;

    // await supabase.from('food').insert({
    //   'name': 'Milk',
    //   'category': 'Dairy',
    //   'expiry_date': '2026-03-25',
    // });

    final data = await supabase.from('food').select();

    print(data.length);
  }

  Future<void> getFood() async {
    final supabase = Supabase.instance.client;
    final temporaryList = await supabase.from('food').select();
    setState(() {
      foodList = temporaryList;
    });
  }

  Future<void> saveFood() async {
    final food = {
      'name': foodNameController.text,
      'category': selectedCategory,
      'expiry_date': selectedDate?.toIso8601String(),
      'amount': double.tryParse(foodAmountController.text),
      'unit': selectedUnit,
      'note': foodNotecontroller.text,
    };
    final supabase = Supabase.instance.client;
    await supabase.from('food').insert(food);
    print('inserted!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food App')),
      body: Center(
        child: ListView.separated(
          itemCount: foodList.length,
          itemBuilder: (context, int index) {
            return ListTile(
              title: Text('${foodList[index]['name']}'),
              subtitle: Column(
                children: [
                  Text(
                    '${foodList[index]['amount']} ${foodList[index]['unit']}',
                  ),
                  Text('Expires on: ${foodList[index]['expiry_date']}'),
                ],
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add_circle_outline),
        onPressed: () => _dialogBuilder(context),
      ),
    );
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add food'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                key: _formKey,
                child: Padding(
                  padding: EdgeInsetsGeometry.all(10.0),
                  child: Column(
                    //mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Name of the food',
                        ),
                        controller: foodNameController,
                        validator: (foodNameController) {
                          if (foodNameController == null ||
                              foodNameController.isEmpty) {
                            return 'Please enter the name of food.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 25),
                      SizedBox(
                        width: 210,
                        child: DropdownMenu(
                          dropdownMenuEntries: <DropdownMenuEntry<String>>[
                            DropdownMenuEntry(value: 'Meat', label: 'Meat'),
                            DropdownMenuEntry(
                              value: 'Vegetable',
                              label: 'Vegetable',
                            ),
                            DropdownMenuEntry(value: 'Grain', label: 'Grain'),
                            DropdownMenuEntry(
                              value: 'Seafood',
                              label: 'Seafood',
                            ),
                            DropdownMenuEntry(value: 'Dairy', label: 'Dairy'),
                            DropdownMenuEntry(
                              value: 'Seasoning',
                              label: 'Seasoning',
                            ),
                          ],
                          label: const Text('Category'),
                          onSelected: (value) {
                            if (value != null) {
                              setState(() {
                                selectedCategory = value;
                              });
                            }
                          },
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final pickedDate = await _selectDate();

                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                              dateError = false;
                            });
                          }
                        },
                        child: Text(() {
                          if (selectedDate != null) {
                            return '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';
                          } else if (dateError == true) {
                            return 'Enter expiry date';
                          }
                          return 'Select expiry date';
                        }()),
                      ),
                      if (dateError)
                        Text(
                          'Select expiry date',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            //width: 100,
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Amount of Food',
                              ),
                              controller: foodAmountController,
                              validator: (foodAmountController) {
                                if (foodAmountController == null ||
                                    foodAmountController.isEmpty) {
                                  return 'Enter an amount';
                                }
                                final parsedAmount = double.tryParse(
                                  foodAmountController,
                                );
                                if (parsedAmount == null) {
                                  return 'Please enter number.';
                                }
                                if (parsedAmount <= 0) {
                                  return 'Too small.';
                                }
                              },
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownMenu(
                              dropdownMenuEntries: <DropdownMenuEntry<String>>[
                                DropdownMenuEntry(value: 'Kg', label: 'Kg'),
                                DropdownMenuEntry(
                                  value: 'Lb(s)',
                                  label: 'Lb(s)',
                                ),
                                DropdownMenuEntry(value: 'Gram', label: 'Gram'),
                                DropdownMenuEntry(value: 'ml', label: 'ml'),
                                DropdownMenuEntry(value: 'Case', label: 'Case'),
                                DropdownMenuEntry(
                                  value: 'Count',
                                  label: 'Count',
                                ),
                              ],
                              label: const Text('Unit'),
                              errorText: unitError,
                              onSelected: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedUnit = value;
                                    unitError = null;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Note'),
                        controller: foodNotecontroller,
                      ),
                      Row(
                        children: [
                          SizedBox(width: 80),
                          ElevatedButton(
                            onPressed: () async {
                              bool hasError = false;
                              if (!_formKey.currentState!.validate()) {
                                hasError = true;
                              }

                              if (selectedUnit == null) {
                                print('validation failed');
                                setState(() {
                                  unitError = 'Enter unit';
                                });

                                hasError = true;
                              }

                              if (selectedDate == null) {
                                setState(() {
                                  dateError = true;
                                });
                                hasError = true;
                              }

                              if (hasError) {
                                return;
                              }

                              try {
                                await saveFood();
                                foodNameController.clear();
                                foodAmountController.clear();
                                foodNotecontroller.clear();
                                selectedCategory = null;
                                selectedDate = null;
                                selectedUnit = null;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Food saved successfully!'),
                                  ),
                                );
                              } catch (e) {
                                print('ERROR: $e');
                              }
                            },
                            child: const Text('Save'),
                          ),
                          ElevatedButton(
                            onPressed: () => print('Cancel button pressed'),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
