import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔴 ضع مفاتيح Firebase الأربعة التي حصلت عليها هنا 🔴
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "اكتب_apiKey_هنا",
      appId: "اكتب_appId_هنا",
      messagingSenderId: "اكتب_messagingSenderId_هنا",
      projectId: "اكتب_projectId_هنا",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "ترويقة ERP",
      theme: ThemeData(primarySwatch: Colors.brown, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String employeeName = "موظف";
  double dollarRate = 15000.0;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      employeeName = prefs.getString('empName') ?? "موظف";
      dollarRate = prefs.getDouble('dollarRate') ?? 15000.0;
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('empName', employeeName);
    await prefs.setDouble('dollarRate', dollarRate);
  }

  void showSettings() {
    final nameCtrl = TextEditingController(text: employeeName);
    final rateCtrl = TextEditingController(text: dollarRate.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("الإعدادات"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "اسم الموظف الحالي"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "سعر الدولار (ل.س)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                employeeName = nameCtrl.text.trim().isEmpty ? "موظف" : nameCtrl.text.trim();
                dollarRate = double.tryParse(rateCtrl.text) ?? 15000.0;
              });
              saveSettings();
              Navigator.pop(c);
            },
            child: const Text("حفظ"),
          ),
        ],
      ),
    );
  }

  void addGroupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("قسم جديد"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: "اسم القسم (معلبات، ألبان)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('groups').add({'name': ctrl.text.trim()});
                Navigator.pop(c);
              }
            },
            child: const Text("إضافة"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ترويقة - الأقسام"),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: showSettings),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.brown[100],
            child: Center(
              child: Text(
                "الموظف: $employeeName | الدولار: ${NumberFormat("#,##0").format(dollarRate)} ل.س",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[800]),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('groups').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final groups = snapshot.data!.docs;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16
                  ),
                  itemCount: groups.length + 1,
                  itemBuilder: (context, index) {
                    if (index == groups.length) {
                      return GestureDetector(
                        onTap: addGroupDialog,
                        child: Container(
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                          child: const Center(child: Icon(Icons.add, size: 48, color: Colors.grey)),
                        ),
                      );
                    }
                    final doc = groups[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (c) => ProductsPage(
                          groupId: doc.id, groupName: doc['name'], empName: employeeName, currentDollar: dollarRate
                        )));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.brown[50], borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6, offset: const Offset(0,4))]
                        ),
                        child: Center(child: Text(doc['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProductsPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String empName;
  final double currentDollar;
  const ProductsPage({super.key, required this.groupId, required this.groupName, required this.empName, required this.currentDollar});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();

  void addProduct() async {
    if (nameCtrl.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('products').add({
        'name': nameCtrl.text.trim(),
        'qty': int.tryParse(qtyCtrl.text) ?? 0,
        'priceUSD': double.tryParse(priceCtrl.text) ?? 0.0,
        'addedBy': widget.empName,
        'date': DateTime.now().toString().substring(0, 10),
      });
      nameCtrl.clear(); qtyCtrl.clear(); priceCtrl.clear();
      Navigator.pop(context);
    }
  }

  void sellProduct(String docId, int currentQty, double priceUsd, String pName) async {
    if (currentQty <= 0) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("الكمية غير كافية!"), backgroundColor: Colors.red));
      return;
    }
    await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('products').doc(docId).update({
      'qty': currentQty - 1,
    });
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم البيع بنجاح!"), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[700], foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text("إضافة منتج"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "اسم المنتج")),
                      TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "الكمية (عدد/كيلو)")),
                      TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "سعر البيع ($)")),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c), child: const Text("إلغاء")),
                    ElevatedButton(onPressed: addProduct, child: const Text("حفظ")),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!.docs;
          if (products.isEmpty) {
            return const Center(child: Text("لا توجد منتجات في هذا القسم", style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              final qty = (p['qty'] ?? 0) as int;
              final price = (p['priceUSD'] ?? 0.0) as double;
              final priceLira = price * widget.currentDollar;

              return Card(
                elevation: 3, margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p['name'] ?? "منتج", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(8)),
                            child: Text("كمية: $qty", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("💲 ${NumberFormat("#,##0").format(price)} $", style: const TextStyle(fontSize: 15)),
                      Text("🇸🇾 ${NumberFormat("#,##0").format(priceLira)} ل.س", style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
                            onPressed: () => sellProduct(p.id, qty, price, p['name']),
                            icon: const Icon(Icons.remove, size: 18), label: const Text("بيع 1"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
