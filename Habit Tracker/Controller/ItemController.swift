//
//  ItemController.swift
//  Habit Tracker
//
//  Created by Dennis Münchow on 14.10.23.
//

import UIKit
import CoreData


class ItemController: UITableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var itemArray = [Item]()
    private let date: Date = Date(timeIntervalSinceReferenceDate: 625_000)
    var selectedCategory: String?
    private var needsUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
         self.title = selectedCategory
         NotificationCenter.default.addObserver(self, selector: #selector(dataSaved), name: Notification.Name("DataSaved"), object: nil)
         loadItems()
         tableView.reloadData()
     }

    @IBAction func backPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
        NotificationCenter.default.post(name: Notification.Name("updateCategoryController"), object: nil)
    }

    @objc func dataSaved() {
        loadItems()
      }
    
      deinit {
          // Vergessen Sie nicht, sich von der Benachrichtigung abzumelden, wenn der Controller nicht mehr benötigt wird
          NotificationCenter.default.removeObserver(self)
      }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemsCell", for: indexPath)
        let item = itemArray[indexPath.row]
        cell.textLabel?.text = item.title
        
        // TERNARY OPERATOR:
        // value = condition ? valueIfTrue : valueIfFalse
        cell.accessoryType = item.done == true ? .checkmark : .none
        
        let date = itemArray[indexPath.row].date
        let formatter = DateFormatter()
        formatter.dateFormat = "E.dd.MMM | HH:mm"
        cell.detailTextLabel?.text = formatter.string(from: date!)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        saveItems()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // delete
        let delete = UIContextualAction(style: .normal, title: "Delete") { (action, view, completionHandler) in
            self.context.delete(self.itemArray[indexPath.row])
            self.itemArray.remove(at: indexPath.row)
            tableView.reloadData()
            completionHandler(true)
        }
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = .red
        // swipe actions
        let swipe = UISwipeActionsConfiguration(actions: [delete])
        return swipe
    }
    
    // MARK: - Add New Item
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "goToAddItem", sender: self)
    }
    
    // MARK: - Model Mamipulation Methods
    
    func saveItems () {
        do {
            try context.save()
        } catch {
            print("Error saving contect \(error)")
        }
        tableView.reloadData()
    }
    
    // Funktion mit zwei Parametern: 01: request , 02: predicate
    // 01 vom Typ Fetch-Request-Objeckt vom Typ NSFetchRequest<HealthItem>, Standardwert = Healthitem.fetchRequest()
    // 02 vom Typ optionales NSPredicate, Standardwert = nil
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
 
        // Filterung: Name der parentCategory MIT Name der selectedCategory
        request.predicate = NSPredicate(format: "category MATCHES %@", selectedCategory!)
 
        do {
            itemArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToAddItem" {
            if let AddController = segue.destination as? AddController {
                AddController.selectedCategory = selectedCategory
                AddController.itemArray = itemArray
            }
        }
    }
}

// MARK: - UISearchBar

extension ItemController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // erstellt ein Request
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        // Filter-Query: %@ = searchBar.text, suche nach Item dessen Titel %@ enthält
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        // Request + Filter-Query
        request.predicate = predicate
        // Sortierung nach title
        request.sortDescriptors  = [NSSortDescriptor(key: "title", ascending: true)]
        
        do {
            itemArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        tableView.reloadData()
    }
    
    // Verhalten, wenn SearchBar bereinigt wird
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
