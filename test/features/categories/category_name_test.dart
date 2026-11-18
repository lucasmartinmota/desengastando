import 'package:desengastando/data/database/app_database.dart';
import 'package:desengastando/features/categories/domain/category_name.dart';
import 'package:desengastando/features/transactions/domain/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

TransactionCategory _category(int id, String name, {bool archived = false}) =>
    TransactionCategory(
      id: id,
      name: name,
      iconKey: 'more_horiz',
      color: 0xFF000000,
      type: TransactionType.expense,
      archived: archived,
      sortOrder: id,
    );

void main() {
  final existing = [
    _category(1, 'Mercado'),
    _category(2, 'Bar', archived: true),
  ];

  test('exige nome', () {
    expect(validateCategoryName('   ', existing), 'Dê um nome à categoria');
  });

  test('aceita nome novo', () {
    expect(validateCategoryName('Pets', existing), isNull);
  });

  test('repetido ignora maiúsculas e espaços', () {
    expect(
      validateCategoryName(' mercado ', existing),
      'Já existe uma categoria com esse nome',
    );
  });

  test('avisa quando o repetido está arquivado', () {
    expect(
      validateCategoryName('bar', existing),
      'Já existe uma categoria arquivada com esse nome',
    );
  });

  test('ao editar, o próprio nome não conta como repetido', () {
    expect(validateCategoryName('Mercado', existing, exceptId: 1), isNull);
  });
}
