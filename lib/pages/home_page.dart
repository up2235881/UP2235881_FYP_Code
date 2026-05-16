import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_settings_page.dart';
import 'unit_lessons_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});


  @override
  Widget build(BuildContext context) {
    final unitsStream = FirebaseFirestore.instance
        .collection('units')
        .where('published', isEqualTo: true)
        .orderBy('order')
        .snapshots();

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Bol Punjabi'),
        centerTitle: true,
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),

        body: StreamBuilder<DocumentSnapshot>(
          stream: user == null
              ? null
              : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

            final points = userData?['totalPoints'] ?? 0;
            final unlockedUnits =
            List<String>.from(userData?['unlockedUnits'] ?? []);

            return Column(
              children: [
                if (user != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_drink, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Lassi Points',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                        Text(
                          '$points',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: unitsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error:\n${snapshot.error}'));
                      }

                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final units = snapshot.data!.docs;

                      if (units.isEmpty) {
                        return const Center(child: Text('No units found.'));
                      }

                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          itemCount: units.length,
                          gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, i) {
                            final doc = units[i];
                            final unitId = doc.id;
                            final title = (doc['title'] ?? '') as String;
                            final description =
                            (doc['description'] ?? '') as String;

                            final isFirstUnit = i == 0;
                            final isUnlocked =
                                isFirstUnit || unlockedUnits.contains(unitId);

                            return Opacity(
                              opacity: isUnlocked ? 1.0 : 0.45,
                              child: InkWell(
                                onTap: isUnlocked
                                    ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UnitLessonsPage(
                                        unitId: unitId,
                                        unitTitle: title,
                                      ),
                                    ),
                                  );
                                }
                                    : null,
                                child: Card(
                                  color: Colors.orange.shade100,
                                  elevation: isUnlocked ? 3 : 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          isUnlocked
                                              ? Icons.menu_book
                                              : Icons.lock,
                                          size: 34,
                                          color: isUnlocked
                                              ? Colors.orange
                                              : Colors.grey,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: isUnlocked
                                                ? Colors.black87
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Expanded(
                                          child: Text(
                                            description,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isUnlocked
                                                  ? Colors.black87
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
    );
  }
}
