//
//  ContentView.swift
//  BetterRest
//
//  Created by Görkem Güray on 13.02.2024.
//
import CoreML
import SwiftUI

struct ContentView: View {

    
    
    @State private var wakeUp = defaultWakeTime
    @State private var sleepAmount = defaultSleepAmount
    @State private var coffeeAmount = defaultCoffeeAmount
    @State private var sleepTime = calculationResult.0
    
    
    @State private var alertTitle = "Error"
    @State private var alertMessage = "Sorry, there was a problem calculating your bedtime."
    @State private var showingAlert = calculationResult.1
    
    static private var defaultSleepAmount = 8.0
    static private var defaultCoffeeAmount = 6
    static private var calculationResult = calculateBedtime()
    
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
    
    static var defaultSleepTime: Date {
        var components = DateComponents()
        components.hour = 22
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
    
    
    static func calculateBedtime(wakeUp: Date = defaultWakeTime, sleepAmount: Double = defaultSleepAmount, coffeeAmount: Int = defaultCoffeeAmount ) -> (Date, Bool) {
        var alertStatus = false
        do {
            alertStatus = false
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60
            let minute = (components.minute ?? 0) * 60
            
            let prediction = try model.prediction(wake: Int64(hour+minute), estimatedSleep: sleepAmount, coffee: Int64(coffeeAmount))
            
            let sleepTime2 = wakeUp - prediction.actualSleep
            return (sleepTime2,alertStatus)
        } catch {
            alertStatus = true
            return (Date.now,alertStatus)
        }
    }
    
    func updateSleepTime() {
        let result = Self.calculateBedtime(wakeUp: wakeUp, sleepAmount: sleepAmount, coffeeAmount: coffeeAmount)
        sleepTime = result.0
        showingAlert = result.1
    }

    
    var body: some View {
        NavigationStack {
            Form {
                Section("When do you want to wake up?") {
                    DatePicker("Please enter a time", selection: $wakeUp, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        .onChange(of: wakeUp) {
                            updateSleepTime()
                        }
                }
                .font(.headline)
                
                Section("Desired amount of sleep"){
                    Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.25)
                        .onChange(of: sleepAmount) {
                            updateSleepTime()
                        }
                }
                .font(.headline)
                
                Section("Daily coffee intake") {
                    Picker("Number of cups", selection: $coffeeAmount) {
                        ForEach(0..<21) {
                            Text("^[\($0) cup](inflect: true)")
                        }
                    }
                    .onChange(of:coffeeAmount) {
                        updateSleepTime()
                    }
                }
                .font(.headline)
                
                Section("Sleep Time:") {
                    Text(sleepTime.formatted(date: .omitted , time: .shortened))
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        .font(.largeTitle.bold())
                }
                .font(.headline)
                
            }
            .navigationTitle("BetterRest")
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {}
                
            } message: {
                Text(alertMessage)
            }
        }
       
    }
    

}

#Preview {
    ContentView()
}
