import 'package:flutter/material.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final List<String> _addresses = [];

  void _addAddress(String address) {
    setState(() {
      _addresses.add(address);
    });
  }

  void _showAddAddressDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Address'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter your address',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_controller.text.trim().isNotEmpty) {
                  _addAddress(_controller.text.trim());
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Addresses'),
        centerTitle: true,
      ),
      body: _addresses.isEmpty
          ? const Center(
              child: Text('No addresses added yet.'),
            )
          : ListView.builder(
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(_addresses[index]),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAddressDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
