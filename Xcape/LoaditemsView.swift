//
//  LoaditemsView.swift
//  Xcape
//
//  Created by Wilson Jno-Baptiste on 1/26/24.
//

import SwiftUI

struct Place: Decodable, Identifiable {
    var id: String { placeid }  // Conform to Identifiable
    let placeid: String
    let whichsite: String
    let distance: Double
    let site:String
}




struct LoaditemsView: View {

    let list = UserDefaults.standard.string(forKey: "list")
    let thislocation:String
    let thisplace:String
    let thisroute:String
    let thissite:String
    
    
    
    @State private var thislist = ""
    @State private var loadactivitylist: [String: String] = [:]
    @State private var places: [Place] = []
    @State private var isLoading = true
    @State private var showPickup = false
    @State private var showList = false
    @State private var cordin = ""
    @State private var placeid = ""
    @State private var site = ""
    @State private var getroute = ""
    @ObservedObject var locationViewModel: LocationViewModel
    
    var body: some View {
        
        NavigationLink(destination: PickupView(thislocation: cordin,thisplace:placeid,thisroute:getroute, thissite:site,locationViewModel: LocationViewModel()), isActive: $showPickup) {
                                      EmptyView()
                                  }
        
        NavigationLink(destination: ListView(), isActive: $showList) {
                                      EmptyView()
                                  }
        
        
   
        
        
     
        VStack{
            
            if list == "2" {
                
                Button(action: {
                  
                    loadDataaz()
                    
                }) { //start
                    Text("Sort A - Z")
                        .frame(width: 300, height: 50)
                        .background(Color.lightGrey)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.top,5)
                }
                
                
                
            }//end if
            
            
            
            
            ScrollView {
                VStack {
                    if isLoading {
                                  Text("Loading...")
                                      .font(.headline)
                                      .foregroundColor(.gray)
                    } else {
                        
                        ForEach(places, id: \.id) { place in
                            Button(action: {
                                
                                showPickup = true
                                
                                let latt = locationViewModel.latitude
                                let longg = locationViewModel.longitude
                               
                                placeid = place.placeid
                                site = place.site
                                
                                getroute = getroute(place:placeid)
                                
                                 
        
                                cordin = "\(latt),\(longg)"
                                print("Selected place: \(placeid)")
                                print("This route: \(getroute)")
                                
                                
                                
                                
                            }) {
                                
                                HStack {
                                                   Image("beachmap32") // Replace with your desired icon
                                                       .foregroundColor(.yellow)
                                                       .frame(width: 32, height: 32) // Fixed size for the image

                                                   Spacer().frame(width: 8) // Adds space between the image and text

                                                   Text("\(place.whichsite) - \(String(format: "%.2f", place.distance)) Miles")
                                                       .frame(maxWidth: .infinity, alignment: .leading) // Ensures text is aligned to the left
                                                       .padding(.vertical)
                                               }
                                               .background(Color.lightBlue)
                                               .foregroundColor(.black)
                                               .cornerRadius(10)
                                               .padding(.horizontal)
                                               .padding(.bottom, 4)
                            }
                        }
                        
                        
                        
                    }
                    
                    
                    
                    
                    
                    
                    
                    
                }
            }
            

                .onAppear {
                    print("list: \(list ?? "0") and \(thislocation)")
                    //let llist = doGetRequestlist()
                    //print("list: \(llist)")
                    
                 
                    
                    //places = parseJson()
                    loadData()
                    
                    
                }
            
        }//end vstack
        
        
        VStack {
            HStack{
                
                Button(action: {
                  
                    showList = true
                    
                }) { //start button click
                Text("< Start")
                    .frame(width: 100, height: 50)
                    .background(Color.lightGrey)
                    .foregroundColor(.black)
                    .cornerRadius(8) //
                    
                    
                }//end button click
                .padding(.leading, 10)
            
                    
                    Text("")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding() //
                    
                    
                    
          
                
                
                
            }//end hstack 1
        }.navigationBarBackButtonHidden(true)
        
    }
    
    func loadData() {
        doGetRequestlists { responseString in
            // Parse the JSON string here
            if let data = responseString.data(using: .utf8) {
                do {
                    self.places = try JSONDecoder().decode([Place].self, from: data)
                } catch {
                    print("JSON parsing error: \(error)")
                    self.places = []
                }
            }
            
            self.isLoading = false  // Update loading status
        }
    }
    
    
    func loadDataaz() {
        doGetRequestlistsaz { responseString in
            // Parse the JSON string here
            if let data = responseString.data(using: .utf8) {
                do {
                    self.places = try JSONDecoder().decode([Place].self, from: data)
                } catch {
                    print("JSON parsing error: \(error)")
                    self.places = []
                }
            }
            
            self.isLoading = false  // Update loading status
        }
    }
    
    
    
    
    
    
 
    
    
    
    
    func getroute(place: String) -> String {
        let url = "https://xcape.ai/navigation/getroute.php?id=\(place)"
        // let url = "https://punchclock.ai/capturePin.php"

       // print("action url: \(url)")
        let session = URLSession.shared

        var responseLocation = ""
        let semaphore = DispatchSemaphore(value: 0)

        guard let urlObj = URL(string: url) else {
            return ""
        }

        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        let body = "getdevice=thisDevice"
        request.httpBody = body.data(using: .utf8)

        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                semaphore.signal()
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                //print("Response code: \(httpResponse.statusCode)")
            }

            if let data = data {
                if let resp = String(data: data, encoding: .utf8) {
                    responseLocation = resp
                    print("respBody:main \(responseLocation)")
                }
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        return responseLocation
    }
    
    

    
    func doGetRequestlistsaz(completion: @escaping (String) -> Void) {
        guard let thisDevice = UIDevice.current.identifierForVendor?.uuidString else {
            completion("")
            return
        }
        
        let url = "https://xcape.ai/navigation/loadlist.php?id=\(list ?? "")&location=\(thislocation)&sortorder=venue"
        print("action click: \(url)")

        guard let urlObj = URL(string: url) else {
            completion("")
            return
        }
        
        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        let body = "getdevice=\(thisDevice)"
        request.httpBody = body.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    completion("")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Response code: \(httpResponse.statusCode)")
                }
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    completion(responseString)
                    print(responseString)
                } else {
                    completion("")
                }
            }
        }
        task.resume()
    }
    
    
    func doGetRequestlists(completion: @escaping (String) -> Void) {
        guard let thisDevice = UIDevice.current.identifierForVendor?.uuidString else {
            completion("")
            return
        }
        
        let url = "https://xcape.ai/navigation/loadlist.php?id=\(list ?? "")&location=\(thislocation)&sortorder="
        print("action load: \(url)")

        guard let urlObj = URL(string: url) else {
            completion("")
            return
        }
        
        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        let body = "getdevice=\(thisDevice)"
        request.httpBody = body.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    completion("")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Response code: \(httpResponse.statusCode)")
                }
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    completion(responseString)
                    print(responseString)
                } else {
                    completion("")
                }
            }
        }
        task.resume()
    }
    
    
    
    
    func doGetRequestlist() -> String {
        guard let thisDevice = UIDevice.current.identifierForVendor?.uuidString else {
            return ""
        }
        
       // let url = "https://xcape.ai/navigation/loadactivities.php"
        let url = "https://xcape.ai/navigation/loadlist.php?id=\(list)&location=\(thislocation)&sortorder=venue"
        
        print("action url: \(url)")
        let session = URLSession.shared
        
        var responseLocation = ""
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let urlObj = URL(string: url) else {
            return ""
        }
        
        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        let body = "getdevice=\(thisDevice)"
        request.httpBody = body.data(using: .utf8)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                semaphore.signal()
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Response code: \(httpResponse.statusCode)")
            }
            
            if let data = data {
                if let resp = String(data: data, encoding: .utf8) {
                    responseLocation = resp
                    print("respBody:main \(responseLocation)")
                }
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        return responseLocation
     }
    
}//end load items

struct LoaditemsView_Previews: PreviewProvider {
    static var previews: some View {
        LoaditemsView(thislocation: "string",thisplace: "string",thisroute: "string", thissite:"string", locationViewModel:LocationViewModel())
    }
}

