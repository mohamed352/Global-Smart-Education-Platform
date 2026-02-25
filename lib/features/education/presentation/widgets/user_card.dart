import 'package:flutter/material.dart';
import 'package:global_smart_education_platform/features/education/data/datasources/local/database.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(user.name),
        subtitle: Text(user.email),
        trailing: Text(
          'آخر تحديث: ${user.updatedAt.hour}:${user.updatedAt.minute}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
