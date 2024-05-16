import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importação necessária para o tema Material Design 3
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart'; // Importação dos ícones do Material Design 3
import 'user.dart';
import 'user_service.dart';

void main() {
  // Definindo o estilo do status bar como escuro para que os ícones da barra de navegação inferior sejam visíveis
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.white,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Flutter de API de Usuário',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // Cor de fundo da barra de aplicativo
          elevation: 0, // Sem sombra na barra de aplicativo
          iconTheme: IconThemeData(color: Colors.black), // Cor dos ícones da barra de aplicativo
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold), // Estilo do texto do título da barra de aplicativo
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white, // Cor de fundo da barra de navegação inferior
          selectedItemColor: Colors.blue, // Cor do item selecionado na barra de navegação inferior
          unselectedItemColor: Colors.black, // Cor dos itens não selecionados na barra de navegação inferior
          showSelectedLabels: true, // Mostrar rótulos dos itens selecionados
          showUnselectedLabels: true, // Mostrar rótulos dos itens não selecionados
        ),
        scaffoldBackgroundColor: Colors.white, // Cor de fundo do scaffold
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TelaPrincipal(),
    );
  }
}

class TelaPrincipal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Usuários'),
      ),
      body: TelaListaUsuario(),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.accountMultiple),
            label: 'Lista',
          ),
          BottomNavigationBarItem(
            icon: Icon(MdiIcons.accountPlus),
            label: 'Adicionar',
          ),
        ],
        onTap: (int index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TelaAdicionarUsuario()),
            );
          }
        },
      ),
    );
  }
}

class TelaListaUsuario extends StatefulWidget {
  @override
  _TelaListaUsuarioState createState() => _TelaListaUsuarioState();
}

class _TelaListaUsuarioState extends State<TelaListaUsuario> {
  late Future<List<User>> futureUsers;
  final UserService userService = UserService();

  @override
  void initState() {
    super.initState();
    futureUsers = userService.getUsers();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: futureUsers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }
          return ListView.builder(
            itemCount: snapshot.data?.length ?? 0,
            itemBuilder: (context, index) {
              User user = snapshot.data![index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(user.picture!),
                ),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text(user.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(MdiIcons.accountEdit),
                      onPressed: () => _showEditDialog(context, user),
                    ),
                    IconButton(
                      icon: Icon(MdiIcons.delete),
                      onPressed: () => _deleteUser(user.id!),
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  void _showEditDialog(BuildContext context, User user) {
    TextEditingController tituloController = TextEditingController(text: user.title);
    TextEditingController firstnameController = TextEditingController(text: user.firstName);
    TextEditingController lastnameController = TextEditingController(text: user.lastName);
    TextEditingController emailController = TextEditingController(text: user.email);
    TextEditingController pictureController = TextEditingController(text: user.picture);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar Usuário"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: tituloController,
                decoration: InputDecoration(labelText: 'Título'),
              ),
              TextFormField(
                controller: firstnameController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              TextFormField(
                controller: lastnameController,
                decoration: InputDecoration(labelText: 'Sobrenome'),
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: pictureController,
                decoration: InputDecoration(labelText: 'URL da Foto'),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Atualizar"),
            onPressed: () {
              Navigator.of(context).pop();
              _updateUser(user, tituloController.text, firstnameController.text, lastnameController.text, emailController.text, pictureController.text);
            },
          ),
        ],
      ),
    );
  }

  void _updateUser(User user, String title, String firstName, String lastName, String email, String picture) {
    Map<String, dynamic> dataToUpdate = {
      'title': title,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'picture': picture,
    };

    userService.updateUser(user.id!, dataToUpdate).then((updatedUser) {
      _showSnackbar('Usuário atualizado com sucesso!');
      _refreshUserList();
    }).catchError((error) {
      _showSnackbar('Falha ao atualizar usuário: $error');
    });
  }

  void _deleteUser(String id) {
    userService.deleteUser(id).then((_) {
      _showSnackbar('Usuário excluído com sucesso!');
      _refreshUserList();
    }).catchError((error) {
      _showSnackbar('Falha ao excluir usuário.');
    });
  }

  void _refreshUserList() {
    setState(() {
      futureUsers = userService.getUsers();
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class TelaAdicionarUsuario extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Usuário'),
      ),
      body: FormularioAdicionarUsuario(),
    );
  }
}

class FormularioAdicionarUsuario extends StatefulWidget {
  @override
  _FormularioAdicionarUsuarioState createState() => _FormularioAdicionarUsuarioState();
}

class _FormularioAdicionarUsuarioState extends State<FormularioAdicionarUsuario> {
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pictureController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: firstnameController,
            decoration: InputDecoration(labelText: 'Nome'),
          ),
          TextFormField(
            controller: lastnameController,
            decoration: InputDecoration(labelText: 'Sobrenome'),
          ),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextFormField(
            controller: pictureController,
            decoration: InputDecoration(labelText: 'URL da Foto'),
          ),
          ElevatedButton(
            onPressed: () {
              _addUser(context);
            },
            child: Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _addUser(BuildContext context) {
    if (firstnameController.text.isNotEmpty &&
        lastnameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        pictureController.text.isNotEmpty) {
      UserService().createUser(User(
        id: '',
        title: '', // Assuming title is not required for adding user
        firstName: firstnameController.text,
        lastName: lastnameController.text,
        email: emailController.text,
        picture: pictureController.text,
      )).then((newUser) {
        _showSnackbar('Usuário adicionado com sucesso!');
        Navigator.pop(context); // Pop the AddUserScreen
      }).catchError((error) {
        _showSnackbar('Falha ao adicionar usuário: $error');
      });
    } else {
      _showSnackbar('Por favor, preencha todos os campos.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
