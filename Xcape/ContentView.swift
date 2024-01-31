//
//  NointernetView.swift
//  MyPunchclock
//
//  Created by Wilson Jno-Baptiste on 6/28/23.
//

import SwiftUI
import CoreLocation
import Foundation
import SystemConfiguration



struct ContentView: View {
    @State private var showContent = false
    
    var body: some View {
        
        NavigationView {
            
            
            VStack {
                
                
                
                NavigationLink(destination: ListView(), isActive: $showContent) {
                    EmptyView()
                }
                
                
                .navigationBarBackButtonHidden(true)
                
                VStack {
                    Text("Looks like you do not have internet. Check and try again")
                        .padding(.horizontal, 20) // Add left and right padding of 20
                        .multilineTextAlignment(.center) // Ce
                    
                    
                    Button(action: {
                        print("cclick ....")
                        showContent = true
                    }) { //start button
                        
                        
                        Text("Try Again")
                            .onDisappear {
                                      //  UIApplication.shared.isIdleTimerDisabled = false
                                    }
                            .onAppear{
                                initfiles()
                                //UIApplication.shared.isIdleTimerDisabled = true
                            }
                            .frame(width: 200, height: 40)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding()
                            .padding(.top,30)
                    
                            
                    }
                    Spacer()
                    
                }
                
                
                
            }
            
            
            
        }//end navigation
        
    }
    
    
    
    func initfiles(){
        
        
        let textToSave = "default|default"
        guard let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("profile.txt") else {
            return
        }
        do {
            try textToSave.write(to: fileURL, atomically: true, encoding: .utf8)
            print("Profile state saved to file.")
        } catch {
            print("Error saving Profile state: \(error.localizedDescription)")
        }
        
        
        let toggleToSave = "off"
        guard let fileURL2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("ToggleState.txt") else {
            return
        }
        do {
            try toggleToSave.write(to: fileURL2, atomically: true, encoding: .utf8)
            print("Toggle state saved to file.")
        } catch {
            print("Error saving Toggle state: \(error.localizedDescription)")
        }
        
        
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
