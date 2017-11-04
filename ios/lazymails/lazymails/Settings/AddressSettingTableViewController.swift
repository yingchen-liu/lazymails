//
//  AddressSettingTableViewController.swift
//  lazymails
//
//  Created by YINGCHEN LIU on 11/10/17.
//  Copyright © 2017 YINGCHEN LIU. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Whisper

class AddressSettingTableViewController: UITableViewController, UISearchBarDelegate, MKLocalSearchCompleterDelegate {
    
    @IBOutlet weak var addressSearchBar: UISearchBar!
    
    
    static let addressPattern = "(\\d+?)\\s*[\\s|/]\\s*(\\d+.*)"
    
    var unit: String?
    
    var addresses: [Dictionary<String, String>] = []
    
    var settingTableDelegate: SettingTableDelegate?
    
    let socket = Socket.shared

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // ✴️ Attributes:
        // Video: Making a Search Bar to Search Words in a TableView (Swift 3)
        // https://www.youtube.com/watch?v=zgP_VHhkroE
        
        addressSearchBar.delegate = self
        addressSearchBar.returnKeyType = .search
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return addresses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addressCell", for: indexPath) as! AddressSettingTableViewCell
        
        guard indexPath.row < addresses.count else {
            return cell
        }
        
        let address = addresses[indexPath.row]

        cell.addressLine1Label.text = address["title"]
        cell.addressLine2Label.text = address["subtitle"]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    /**
     Search address
     - Parameters:
         - searchBar: UIsearchBar
         - searchText: search text input
     */
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        addresses.removeAll()
        unit = nil
        
        if searchText != "" {
            let completer = MKLocalSearchCompleter()
            completer.delegate = self
            completer.queryFragment = searchText
            
            do {
                // ✴️ Attributes:
                // Website: NSRegularExpression: How to match regular expressions in strings
                //  https://www.hackingwithswift.com/example-code/strings/nsregularexpression-how-to-match-regular-expressions-in-strings
                
                // ✴️ Attributes:
                // Website: NSRegular​Expression
                //  http://nshipster.com/nsregularexpression/
                
                // ✴️ Attributes:
                // Stackoverflow: NSRegularExpression cannot find capturing group matches
                //  https://stackoverflow.com/questions/31499221/nsregularexpression-cannot-find-capturing-group-matches
                
                let addressRegex = try NSRegularExpression(pattern: AddressSettingTableViewController.addressPattern, options: .caseInsensitive)
                var addressResults = addressRegex.matches(in: searchText, options: [], range: NSRange(location: 0, length: searchText.utf16.count))
                
                if addressResults.count > 0 {
                    unit = (searchText as NSString).substring(with: addressResults[0].range(at: 1))
                    completer.queryFragment = (searchText as NSString).substring(with: addressResults[0].range(at: 2))
                }
            } catch {
                // TODO: show error
                print("error")
            }
        }
        tableView.reloadData()
    }
    
    /**
     Update address results
     
     */
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        for result in completer.results {
            let title = "\(unit != nil ? "Unit \(unit!) " : "")\(result.title)"
            addresses.append(["title": title, "subtitle": result.subtitle])
        }
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // ✴️ Attributes:
        // Website: Forward Geocoding With CLGeocoder
        // https://cocoacasts.com/forward-and-reverse-geocoding-with-clgeocoder-part-1/
        // ✴️ Attributes:
        // Apple: CLGeocoder
        // https://developer.apple.com/documentation/corelocation/clgeocoder
        
        let geocoder = CLGeocoder();
        let address = addresses[indexPath.row]
        
        geocoder.geocodeAddressString("\(address["title"]!), \(address["subtitle"]!)") { (placemark, error) in
            guard error == nil else {
                // TODO: show error
                self.showError(message: "Error occurs when geocode address: \(error!)")
                return
            }
            
            if let placemark = placemark {
                let place = placemark[0]
                
                if let streetNo = place.subThoroughfare, let street = place.thoroughfare?.uppercased(), let suburb = place.locality?.uppercased(), let state = place.administrativeArea?.uppercased(), let postalCode = place.postalCode {
                    
                    let streetName = street.components(separatedBy: " ")[0]
                    let streetType = street.components(separatedBy: " ")[1]
                    
                    let address = Address(unit: self.unit?.uppercased(), streetNo: streetNo, streetName: streetName, streetType: streetType, suburb: suburb, state: state, postalCode: postalCode)
                    
                    let setting = Setting.shared
                    setting.address = address
                    setting.save()
                    
                    self.socket.sendUpdateMailboxMessage { (error, message) in
                        guard error == nil else {
                            self.showError(message: "Error occurs when updating mailbox setting to server: \(error!)")
                            return
                        }
                    }
                    
                    self.settingTableDelegate?.editAddress(address: address)
                    self.navigationController?.popViewController(animated: true)
                } else {
                    self.showNotValidAddressToast()
                }
            } else {
                self.showNotValidAddressToast()
            }
        }
    }
    
    /**
     Show address is not valid
     
     */
    func showNotValidAddressToast() {
        let message = Message(title: "This is not a valid address, please input your street number.", backgroundColor: .red)
        
        Whisper.show(whisper: message, to: self.navigationController!, action: .show)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
