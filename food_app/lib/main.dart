import 'dart:ffi';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'http://10.0.2.2:54321', // Android emulator
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
  );

  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  final LinuxInitializationSettings initializationSettingsLinux =
      LinuxInitializationSettings(defaultActionName: 'Open notification');
  final WindowsInitializationSettings initializationSettingsWindows =
      WindowsInitializationSettings(
        appName: 'Flutter Local Notifications Example',
        appUserModelId: 'Com.Dexterous.FlutterLocalNotificationsExample',
        // Search online for GUID generators to make your own
        guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
      );
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
    linux: initializationSettingsLinux,
    windows: initializationSettingsWindows,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  print(
    'Can schedule exact notifications: '
    '${await androidPlugin?.canScheduleExactNotifications()}',
  );

  await androidPlugin?.requestNotificationsPermission();
  await androidPlugin?.requestExactAlarmsPermission();

  tz.initializeTimeZones();
  runApp(const MyApp());

  //tz.setLocalLocation(tz.getLocation('America/Vancouver'));
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

  void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
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

  Future<Map<String, dynamic>> saveFood() async {
    final food = {
      'name': foodNameController.text,
      'category': selectedCategory,
      'expiry_date': selectedDate?.toIso8601String(),
      'amount': double.tryParse(foodAmountController.text),
      'unit': selectedUnit,
      'note': foodNotecontroller.text,
    };
    final supabase = Supabase.instance.client;
    final insertedFood = await supabase
        .from('food')
        .insert(food)
        .select('id, name');
    print(insertedFood[0]);
    return (insertedFood[0]);
  }

  Future<void> deleteFood(int id) async {
    final supabase = Supabase.instance.client;
    await supabase.from('food').delete().eq('id', id);
  }

  Future<void> editFood(int id) async {
    final food = {
      'name': foodNameController.text,
      'category': selectedCategory,
      'expiry_date': selectedDate?.toIso8601String(),
      'amount': double.tryParse(foodAmountController.text),
      'unit': selectedUnit,
      'note': foodNotecontroller.text,
    };
    final supabase = Supabase.instance.client;
    await supabase.from('food').update(food).eq('id', id);
  }

  void clearFields() {
    foodNameController.clear();
    foodAmountController.clear();
    foodNotecontroller.clear();
    setState(() {
      selectedCategory = null;
      selectedDate = null;
      selectedUnit = null;
    });
  }

  tz.TZDateTime notificationTime(DateTime date) {
    return tz.TZDateTime.from(date, tz.local).subtract(const Duration(days: 1));
  }

  NotificationDetails createNotoficationDetails() {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    return notificationDetails;
  }

  Future<void> scheduleNotification(
    NotificationDetails notificationDetails,
    Map food,
  ) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: food['id'],
      title: 'Expiry Notification',
      body: '${food['name']} expires tomorrow!',
      notificationDetails: notificationDetails,
      payload: 'item x',
      scheduledDate: notificationTime(selectedDate!),
      androidScheduleMode: AndroidScheduleMode.exact,
    );
  }

  void testNotification() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    if (selectedDate != null) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: 0,
        title: 'Test Notification',
        body: 'Notification After 30 secs',
        notificationDetails: notificationDetails,
        payload: 'item x',
        scheduledDate: notificationTime(selectedDate!),
        androidScheduleMode: AndroidScheduleMode.exact,
      );
      print('selected date is not null');
    } else {
      print('selected date is null');
    }
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      foodNameController.text = '${foodList[index]['name']}';
                      selectedCategory = foodList[index]['category'];
                      selectedDate = DateTime.parse(
                        foodList[index]['expiry_date'],
                      );
                      foodAmountController.text = (foodList[index]['amount'])
                          .toString();
                      selectedUnit = foodList[index]['unit'];
                      foodNotecontroller.text =
                          '${foodList[index]['note']}' ?? '';
                      _dialogBuilder(context, 'edit', foodList[index]);
                    },
                    icon: Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Delete Window'),
                            content: Text(
                              'Are you sure you want to delete ${foodList[index]['name']}? \nYou cannot undone this action.',
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await deleteFood(foodList[index]['id']);
                                    await getFood();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Food deleted successfully!',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    print('error: ${e}');
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.delete),
                  ),
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
        onPressed: () {
          clearFields();
          _dialogBuilder(context, 'add', null);
          //testNotification();
        },
      ),
    );
  }

  Future<void> _dialogBuilder(
    BuildContext context,
    String mode,
    Map<String, dynamic>? food,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(mode == 'add' ? 'Add food' : 'Edit food'),
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
                          initialSelection: selectedCategory,
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
                              initialSelection: selectedUnit,
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
                          SizedBox(width: 33),

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
                                if (mode == 'add') {
                                  final foodId = await saveFood();
                                  NotificationDetails notificationDetail =
                                      createNotoficationDetails();
                                  await scheduleNotification(
                                    notificationDetail,
                                    foodId,
                                  );

                                  //Display the pending notifications in the console
                                  final pendingNotifications =
                                      await flutterLocalNotificationsPlugin
                                          .pendingNotificationRequests();

                                  for (final notification
                                      in pendingNotifications) {
                                    print('ID: ${notification.id}');
                                    print('Title: ${notification.title}');
                                    print('Body: ${notification.body}');
                                  }
                                } else {
                                  await editFood(food!['id']);
                                }
                                foodNameController.clear();
                                foodAmountController.clear();
                                foodNotecontroller.clear();
                                selectedCategory = null;
                                selectedDate = null;
                                selectedUnit = null;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      mode == 'add'
                                          ? 'Food saved successfully!'
                                          : 'Food edited successfully!',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                print('ERROR: $e');
                              }
                              await getFood();
                            },
                            child: Text(
                              mode == 'add' ? 'Save' : 'Save changes',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
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
