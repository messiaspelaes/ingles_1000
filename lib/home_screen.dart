import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Para ícones SVG
import 'features/import/import_screen.dart';
import 'features/study/study_screen.dart';
import 'core/license/about_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Phrases Master',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              const SizedBox(height: 40),
              SvgPicture.asset(
                'assets/logo.svg', // Substitua por seu logo
                height: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Aprenda as 1000 frases\nmais usadas em inglês',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              // Botão de importar
              _buildOptionCard(
                context,
                icon: Icons.upload_file,
                title: "Importar Deck",
                subtitle: "Importe arquivos .apkg do Anki",
                color: Colors.purple[400]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImportScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Botão de estudo
              _buildOptionCard(
                context,
                icon: Icons.school,
                title: "Começar a Estudar",
                subtitle: "Pratique com as frases essenciais",
                color: Colors.blue[400]!,
                onTap: () {
                  // Navegar para tela de estudo
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudyScreen()),
                  );
                },
              ),

              const SizedBox(height: 30),

              // Botão de progresso
              _buildOptionCard(
                context,
                icon: Icons.assessment,
                title: "Meu Progresso",
                subtitle: "Veja seu gráfico de memorização",
                color: Colors.green[400]!,
                onTap: () {
                  // Navegar para tela de gráfico
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProgressScreen()),
                  );
                },
              ),

              // Rodapé
              const Spacer(),
              const Text(
                "Baseado no algoritmo FSRS de repetição espaçada",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Sobre / Licenças',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
