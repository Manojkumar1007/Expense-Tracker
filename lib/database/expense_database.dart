import 'dart:async';

import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class ExpenseDatabase extends ChangeNotifier{
  static late Isar isar;
  List<Expense> _allExpenses = [] ;

  //initialize db
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path) ;
  }

  List<Expense> get allExpense => _allExpenses ;

  //create

  Future<void> createNewExpense(Expense newExpense) async {
    await isar.writeTxn(() => isar.expenses.put(newExpense));

    await readExpenses();
  }

  //read

  Future<void> readExpenses() async {
    List<Expense> fetchedExpenses = await isar.expenses.where().findAll();

    _allExpenses.clear();
    _allExpenses.addAll(fetchedExpenses);

    notifyListeners();
  }

  //update

  Future<void> updateExpense(int id, Expense updatedExpense) async {
    
    updatedExpense.id = id ;
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));
    await readExpenses();

  }

  //delete
  Future<void> deleteExpense(int id) async {
    await isar.writeTxn(() => isar.expenses.delete(id));
    await readExpenses();
  }

  Future<Map<String, double>> calculateMonthlyTotals() async {
    await readExpenses();

    Map<String, double> monthlyTotals = {};

    for(var expense in _allExpenses){
      //int month = expense.date.month;
      String yearMonth = '${expense.date.year}-${expense.date.month}' ;

      if(!monthlyTotals.containsKey(yearMonth)){
        monthlyTotals[yearMonth] = 0 ;
      }
      monthlyTotals[yearMonth] = monthlyTotals[yearMonth]! + expense.amount ;
    }

    return monthlyTotals;
  }

  Future<double> calculateCurrentMonthTotal() async {
    await readExpenses();

    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    List<Expense> currentMonthExpenses = _allExpenses.where((expense){
      return expense.date.month == currentMonth && expense.date.year == currentYear;
    }).toList();

    double total = currentMonthExpenses.fold(0, (sum, expense) => sum + expense.amount);
    return total;
  }

  int getStartMonth(){
    if(_allExpenses.isEmpty){
      return DateTime.now().month;
    }

    _allExpenses.sort((a,b) => a.date.compareTo(b.date),);
    return _allExpenses.first.date.month;
  }

  int getStartYear(){
    if(_allExpenses.isEmpty){
      return DateTime.now().year;
    }

    _allExpenses.sort((a,b) => a.date.compareTo(b.date),);
    return _allExpenses.first.date.year;
  }

}