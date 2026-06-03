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
  DateTime? selectedDate;
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

    await supabase.from('food').insert({
      'name': 'Milk',
      'category': 'Dairy',
      'expiry_date': '2026-03-25',
    });

    print('Inserted!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food App')),
      body: Center(
        child: ElevatedButton(
          onPressed: addFood,
          child: const Text('Add Food'),
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
                child: Padding(
                  padding: EdgeInsetsGeometry.all(10.0),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Name of the food',
                        ),
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
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final pickedDate = await _selectDate();

                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select expiry date',
                        ),
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
