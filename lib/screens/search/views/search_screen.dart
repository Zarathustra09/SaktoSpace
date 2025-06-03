import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Sample product list
  final List<Map<String, dynamic>> _allProducts = [
    {'name': 'Red Shirt', 'category': 'Clothing', 'price': 29.99},
    {'name': 'Blue Jeans', 'category': 'Clothing', 'price': 49.99},
    {'name': 'Running Shoes', 'category': 'Footwear', 'price': 89.99},
    {'name': 'Smart Watch', 'category': 'Accessories', 'price': 199.99},
    {'name': 'Leather Wallet', 'category': 'Accessories', 'price': 59.99},
    {'name': 'White Sneakers', 'category': 'Footwear', 'price': 79.99},
    {'name': 'Black T-Shirt', 'category': 'Clothing', 'price': 19.99},
    {'name': 'Baseball Cap', 'category': 'Accessories', 'price': 24.99},
  ];

  List<Map<String, dynamic>> _filteredProducts = [];

  // Filter options
  final List<String> _categories = [
    'All',
    'Clothing',
    'Footwear',
    'Accessories'
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(_allProducts);
  }

  void _filterProducts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final nameMatch = product['name'].toLowerCase().contains(query);
        final categoryMatch = _selectedCategory == 'All' ||
            product['category'] == _selectedCategory;
        return nameMatch && categoryMatch;
      }).toList();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedCategory = 'All';
      _filteredProducts = List.from(_allProducts);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _filterProducts(),
              decoration: InputDecoration(
                hintText: 'Search for products',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          // Category Filters
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                        _filterProducts();
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Product List
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(child: Text('No products found.'))
                : ListView.builder(
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return ListTile(
                        title: Text(product['name']),
                        subtitle: Text(
                            '${product['category']} - \$${product['price']}'),
                        onTap: () {
                          // Navigate to product details
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
