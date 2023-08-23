import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class Book {
  final int id;
  final String title;
  final String author;
  final String classification;
  final String? coverImagePath;

  Book({required this.id, required this.title, required this.author, required this.classification, this.coverImagePath});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'classification': classification,
      'coverImagePath': coverImagePath,
    };
  }
}

class DatabaseHelper {
  late Database _database;

  DatabaseHelper() {
    _openDatabase();
  }

  Future<void> _openDatabase() async {
  _database = await openDatabase(
    join(await getDatabasesPath(), 'book_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE books(id INTEGER PRIMARY KEY, title TEXT, author TEXT, classification TEXT, coverImagePath TEXT)',
      );
    },
    version: 1,
  );
}

  Future<void> insertBook(Book book) async {
    await _openDatabase();
    await _database.insert(
      'books',
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Book>> getBooks() async {
    await _openDatabase();
    final List<Map<String, dynamic>> maps = await _database.query('books');
    return List.generate(maps.length, (i) {
      return Book(
        id: maps[i]['id'],
        title: maps[i]['title'],
        author: maps[i]['author'],
        classification: maps[i]['classification'],
        coverImagePath: maps[i]['coverImagePath'],
      );
    });
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Livros',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: BookListScreen(),
    );
  }
}

class BookListScreen extends StatefulWidget {
  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _authorController = TextEditingController();
  TextEditingController _classificationController = TextEditingController();
  List<Book> books = [];

  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    books = await DatabaseHelper().getBooks();
    setState(() {});
  }

  Future<void> _selectImage() async {
    final pickedImage = await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  void _addBook() async {
    final newBook = Book(
      id: DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text,
      author: _authorController.text,
      classification: _classificationController.text,
      coverImagePath: _selectedImage?.path,
    );

    await DatabaseHelper().insertBook(newBook);
    _loadBooks();

    _titleController.clear();
    _authorController.clear();
    _classificationController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cadastro de Livros'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_selectedImage != null)
                  Image.file(_selectedImage!, height: 100),
                ElevatedButton(
                  onPressed: _selectImage,
                  child: Text('Selecionar Capa'),
                ),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Título'),
                ),
                TextField(
                  controller: _authorController,
                  decoration: InputDecoration(labelText: 'Autor'),
                ),
                TextField(
                  controller: _classificationController,
                  decoration: InputDecoration(labelText: 'Classificação'),
                ),
                ElevatedButton(
                  onPressed: _addBook,
                  child: Text('Adicionar Livro'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  title: Text(book.title),
                  subtitle: Text('${book.author}, ${book.classification}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailScreen(book),
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

class BookDetailScreen extends StatelessWidget {
  final Book book;

  BookDetailScreen(this.book);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Livro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Título: ${book.title}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Autor: ${book.author}', style: TextStyle(fontSize: 18)),
            Text('Classificação: ${book.classification}', style: TextStyle(fontSize: 18)),
            if (book.coverImagePath != null)
              Image.file(File(book.coverImagePath!), height: 200),
          ],
        ),
      ),
    );
  }
}
