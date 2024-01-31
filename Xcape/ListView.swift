//
//  ListView.swift
//  Xcape
//
//  Created by Wilson Jno-Baptiste on 1/25/24.
//

import SwiftUI
import CoreLocation
import Combine
import AVFoundation

struct Waypoint: Decodable {
    let latlng: String
    let speak: String
    let bearing: Double
    let triggerrange: Double

    var coordinate: CLLocationCoordinate2D {
        let latLon = latlng.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0 }
        return CLLocationCoordinate2D(latitude: latLon[0], longitude: latLon[1])
    }
    
    
    enum CodingKeys: String, CodingKey {
        case latlng, speak, bearing, triggerrange
    }
    
}


class LocationViewModel: NSObject, CLLocationManagerDelegate,ObservableObject {
    private let locationManager = CLLocationManager()
    
    
    var isToggleOn: Bool = false
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var currentBearing: Double = 0
    var getfile: String = ""
    @Published var currentLocation: CLLocation?
    var distanceAndTimeText: String = "Calculating....."
    private var timer: AnyCancellable?
    @State var waypoints: [Waypoint] = []
    var speechSynthesizer = AVSpeechSynthesizer()
    private var headingUpdateTimer: Timer?
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 10;
         locationManager.startUpdatingLocation()
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation


        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.showsBackgroundLocationIndicator = true
         locationManager.startUpdatingHeading()
        
   
    }
    
    
    func stopLocationUpdates() {
            locationManager.stopUpdatingLocation()
        }
    
    func startTimer(loadlat:Double, loadlong:Double, routelatitude: Double, routelongitude: Double) {
        // Cancel existing timer if it exists
        timer?.cancel()
        
        print("timer 1: \(self.latitude), Longitude 1: \( self.longitude)")
           print("timer 2: \(routelatitude), Longitude 2: \(routelongitude)")
        
        self.distanceAndTimeText = self.estimateDrivingTimeAndDistance(lat1: loadlat, lon1: loadlong, lat2: routelatitude, lon2: routelongitude, averageSpeedInMPH: 20)

        timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
            .sink { _ in
                print("Timer fired")
                DispatchQueue.main.async {
                    
                    self.distanceAndTimeText = self.estimateDrivingTimeAndDistance(lat1: self.latitude, lon1: self.longitude, lat2: routelatitude, lon2: routelongitude, averageSpeedInMPH: 20)
                }
            }
    }
    
    
     func loadWaypoints() {
           let waypointJsonString = getwaymarkers()

           guard let jsonData = waypointJsonString.data(using: .utf8) else { return }
           do {
               waypoints = try JSONDecoder().decode([Waypoint].self, from: jsonData)
           } catch {
               print("Error decoding waypoints: \(error)")
           }
       }
    
    func checkWaypointsAndUpdate() {
            guard let currentLocation = currentLocation else { return }
            
            for (index, waypoint) in waypoints.enumerated().reversed() {
                let waypointLocation = CLLocation(latitude: waypoint.coordinate.latitude, longitude: waypoint.coordinate.longitude)
                let distance = currentLocation.distance(from: waypointLocation)
                let bearingDifference = abs(currentBearing - waypoint.bearing)
                
                if distance <= waypoint.triggerrange,
                   bearingDifference <= 20 || (360 - bearingDifference) <= 20 {
                    speechSynthesizer.speak(AVSpeechUtterance(string: waypoint.speak))
                    waypoints.remove(at: index)
                }
            }
        }
    
    func getwaymarkers() -> String {
        let url = "https://xcape.ai/navigation/loadwaymarkers.php"
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
    
    func estimateDrivingTimeAndDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double, averageSpeedInMPH: Double) -> String {
        // Haversine formula to calculate the distance
        
        print("Latitude 1: \(lat1), Longitude 1: \(lon1)")
           print("Latitude 2: \(lat2), Longitude 2: \(lon2)")
           print("Average Speed in MPH: \(averageSpeedInMPH)")

        
        let earthRadius: Double = 3959 // Radius of the earth in miles
        let dLat = deg2rad(lat2 - lat1)
        let dLon = deg2rad(lon2 - lon1)
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(deg2rad(lat1)) * cos(deg2rad(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        let distanceInMiles = earthRadius * c

        // Calculate driving time
        if distanceInMiles <= 0 || averageSpeedInMPH <= 0 {
            return "Invalid input values"
        }
        let drivingTimeHours = distanceInMiles / averageSpeedInMPH
        let drivingTimeMinutes = Int(drivingTimeHours * 60)

        print ("\(drivingTimeMinutes) mins - \(String(format: "%.2f", distanceInMiles)) mi")
        distanceAndTimeText = "6787"
        return "\(drivingTimeMinutes) mins - \(String(format: "%.2f", distanceInMiles)) mi"
    }

    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }

    

    
    func stopTimer() {
            timer?.cancel()
        }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.headingUpdateTimer?.invalidate()
        self.headingUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            DispatchQueue.main.async {
                print("======= didUpdateHeading called ======")
                self.currentBearing = newHeading.trueHeading  // trueHeading is the heading relative to the geographic North Pole
            }
        }
    }

    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("No locations found")
            return
            
           
        }
        print("======= didUpdateLocations called ======")
        //checkWaypointsAndUpdate()
        currentLocation = locations.last
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        
        /*
        if location.course >= 0 {  // Check if the course is valid
                bearing = location.course
            }
        */
        
        
        let mylocation =  "\(latitude),\(longitude)"
        
        
       
       // let getprfile = readProfile()
       
       
       
        
        
        print("New location - Latitude: \(latitude), Longitude: \(longitude)")
     
        // Call your function here using the updated latitude and longitude
    }
    
    
    
    func disableBackgroundLocationUpdates() {
        locationManager.allowsBackgroundLocationUpdates = false
          }
      
      func enableBackgroundLocationUpdates() {
          locationManager.allowsBackgroundLocationUpdates = true
          }


    private func readProfile() -> String {
        
      
        
            guard let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("profile.txt") else {
                return ""
            }
            do {
                getfile = try String(contentsOf: fileURL, encoding: .utf8)
                print("File contentsx: \(getfile)")
            } catch {
                print("Error reading file: \(error.localizedDescription)")
            }
        
        return getfile
        }
    
    
    
} //end class



extension Color {
    static let lightBlue = Color(red: 173 / 255, green: 216 / 255, blue: 230 / 255)
    static let lightGrey = Color(red: 211 / 255, green: 211 / 255, blue: 211 / 255)

}


struct ListView: View {
   // @State private var loadactivity = ""
    @State private var loadactivity: [String: String] = [:]
   // @State private var list = ""
    @State private var list: String? = nil // Variable to store cunq
    
    @State private var showList = false
    @State private var cordin = ""
    private let locationViewModel = LocationViewModel()
    @State private var placeid = ""
    @State private var site = ""
    @State private var route = ""
    
    var body: some View {
        
        
        NavigationLink(destination: LoaditemsView(thislocation: cordin,thisplace:placeid,thisroute: route, thissite: site, locationViewModel: LocationViewModel()), isActive: $showList) {
                                      EmptyView()
                                  }
      
            
        VStack{
            
            
            Text("Select your activity")
                .font(.headline)
            
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .padding(.bottom,10)
                .padding(25)
            
            
            ScrollView {
                VStack {
                    
                    
                    
                    ForEach(Array(loadactivity.keys).sorted(), id: \.self) { key in
                              if let activity = loadactivity[key] {
                                  Button(action: {
                                      print("Selected activity key: \(key), activity: \(activity)")
                                      
                                      let latt = locationViewModel.latitude
                                      let longg = locationViewModel.longitude
                                       
                                       
                                
                                      print("prelosd: \(latt),\(longg)")
                                      
                                      cordin = "\(latt),\(longg)"
                                      list = key
                                      UserDefaults.standard.set(list, forKey: "list")
                                      showList = true
                                      
                                  }) {
                                      HStack {
                                          Image("beachmap32")   // Replace with your desired icon
                                                          .foregroundColor(.yellow)    // Optional: Set the color of the icon

                                                      Text(activity)
                                                          .frame(maxWidth: .infinity, alignment: .leading) // Aligns text to the left
                                                          .padding()
                                                  }
                                                  .background(Color.lightBlue)
                                                  .foregroundColor(.black)
                                                  .cornerRadius(10)
                                                  .padding(4)
                                  }
                              }
                          }

                          // Manually adding extra buttons
                          Button(action: {
                              // Define action for this button
                              print("Extra Button 1 Tapped")
                          }) {
                              Text("Extra Button 1")
                                  .padding()
                                  .frame(maxWidth: .infinity)
                                  .background(Color.red)
                                  .foregroundColor(.white)
                                  .cornerRadius(10)
                                  .padding(4)
                          }

                          Button(action: {
                              // Define action for this button
                              print("Extra Button 2 Tapped")
                          }) {
                              Text("Extra Button 2")
                                  .padding()
                                  .frame(maxWidth: .infinity)
                                  .background(Color.orange)
                                  .foregroundColor(.white)
                                  .cornerRadius(10)
                                  .padding(4)
                          }
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                       }
                
                
                      }
                  }
                
                .onAppear {
                    //timerManager.start()
                    
                    parseJson()
                    
                   
                   print("loading")
                    
                    
                }
            
            
        }//end vstact1
        
     


func parseJson() {
    let jsonString =  doGetRequest()
    print("device: \(jsonString)")
    if let data = jsonString.data(using: .utf8) {
        do {
            loadactivity = try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            print("Error parsing JSON: \(error)")
        }
    }
}



func doGetRequest() -> String {
    guard let thisDevice = UIDevice.current.identifierForVendor?.uuidString else {
        return ""
    }
    
    let url = "https://xcape.ai/navigation/loadactivities.php"
    
    
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
}

struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        ListView()
    }
}
