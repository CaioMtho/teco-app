import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';

const _kPrimary = Color(0xFF0A0A0A);
const _kAccent = Color.fromARGB(255, 246, 244, 244);
const _kButton = Color(0xFF1E1E1E);
const _kMuted = Color(0xFF6B6B6B);

  
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsPage> {
  bool isDarkMode = true;
  bool notificationsEnabled = true;

    Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta', style: TextStyle(
          color: Colors.red,
        )),
        content: const Text('Tem certeza que deseja encerrar sua sessão?', style: TextStyle(
          color: _kAccent,
        ),),
        backgroundColor: _kButton,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(
          color: _kAccent,
        )),
            
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    Navigator.of(context).popUntil((route) => route.isFirst);

    await SupabaseService.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: _kPrimary,
      
      appBar: AppBar(
        title: Text('Configurações', style: TextStyle(
          color: _kAccent,
        )),
        backgroundColor: _kPrimary,

        leading: IconButton(
        icon: Icon(Icons.close, color: _kAccent),
        
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      ),
      body: ListView(
        
        children: [
          
          SwitchListTile(
            title: Text('Modo Escuro', style: TextStyle(
          color: _kAccent,
        )),
            value: isDarkMode,

            onChanged: (value) {
              setState(() {
                isDarkMode = value;
              });
            },
            secondary: Icon(Icons.dark_mode, color: _kAccent),
            
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('Sobre'),
            textColor: _kAccent,
            iconColor: _kAccent,
            onTap: () {
              showDialog(
                context: context,
                
                builder: (_) => AlertDialog(
                  backgroundColor: _kButton,
                  title: Text('Sobre', style: TextStyle(
                    color: _kAccent,
                  )),
                  
                  content: Text('A Teco Corporation é uma empresa de tecnologia da informação cujo produto único e principal até então é a plataforma Teco. Nossa missão é facilitar o acesso a suporte técnico confiável, rápido e acessível, conectando pessoas a profissionais qualificados com eficiência e transparência. Procuramos ser a principal plataforma de serviços técnicos sob demanda na cidade de São Paulo. A empresa conta com um time de desenvolvimento de 6 integrantes.', style: TextStyle(
                    color: _kAccent,
                  )),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Fechar', style: TextStyle(
                        color: _kAccent,
                      )),
                    )
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sair da conta'),
            textColor: Colors.red,
            iconColor: _kAccent,
            onTap: () {
              _logout();
            },
          ),
          
        ],
      ),
    );
  }
}

