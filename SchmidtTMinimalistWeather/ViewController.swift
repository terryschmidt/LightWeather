//  ViewController.swift
//  SchmidtTMinimalistWeather
//
//  Created by terry schmidt on 5/31/15.
//  Copyright (c) 2015 terry schmidt. All rights reserved.
//
//  Terry Schmidt, June 2015, CSC 471, Final Project

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var currentTemperatureLabel: UILabel!
    @IBOutlet weak var rainSnowLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var currentWeatherIcon: UIImageView!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var latTextBox: UITextField!
    @IBOutlet weak var lonTextBox: UITextField!
    var isUsingCustomCoordinates = false
    var locationManager = CLLocationManager()
    let APIkey = "616071c2fbe0a49da3911a7053d960d3"
    lazy var lat = 41.88 // used to store the current latitude coordinate
    lazy var lon = -87.62 // used to store the current longitude coordinate
    //41.88, -87.62 is chicago
    
    override func viewWillAppear(animated: Bool) {
        self.locationManager.requestWhenInUseAuthorization()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.latTextBox.delegate = self
        self.lonTextBox.delegate = self
        if (CLLocationManager.locationServicesEnabled()) { // if they allowed me to use location services...
            locationManager.delegate = self // name this class the delegate
            locationManager.desiredAccuracy = kCLLocationAccuracyBest // set the accuracy
            locationManager.startUpdatingLocation() // start updating
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) { // this function is called when using startUpdatingLocation.  It gives the location to this function.
        if (isUsingCustomCoordinates == false) {
            var locValue: CLLocationCoordinate2D = manager.location.coordinate // put the coordinates in this variable
            self.lat = locValue.latitude // set global variable to current latitude
            self.lon = locValue.longitude // set global variable to current longitude
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) { // if this gets called, it means it couldn't find location
        println("Error while updating location " + error.localizedDescription) // log message
        locationManager.stopUpdatingLocation() // stop whatever it's doing..
        usleep(1_000_000) // wait a second...
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // reset the accuracy
        locationManager.startUpdatingLocation() // try again.
    }
    
    func locationManagerDidPauseLocationUpdates(manager: CLLocationManager!) {
        
    }


    func getWeather() { // function to get the weather
        if (CLLocationManager.locationServicesEnabled()) { // if location services is enabled...
            let forecast = Forecast(APIkeyArg: APIkey) // create forecast object with my API key
            print("Coordinates about to be used: \(self.lat)") // just a log message
            println(" \(self.lon)")
            self.latitudeLabel.text = "LATITUDE: \(self.lat)" // set latitude in UI
            self.longitudeLabel.text = "LONGITUDE: \(self.lon)" // set longitude in UI
            forecast.getData(self.lat, lon: self.lon) { // call getData function on our forecast object, pass in the current coordinates
                (let currently) in
                if let currentWeather = currently {
                    dispatch_async(dispatch_get_main_queue()) { // update UI asynchronously
                        if let temperature = currentWeather.temperature {
                            self.currentTemperatureLabel?.text = "\(temperature)º" // set the temperature label
                        }
                    
                        if let humidity = currentWeather.humidity {
                            self.humidityLabel?.text = "\(humidity)%" // set humidity
                        }
                    
                        if let precipitation = currentWeather.precipProbability {
                            self.rainSnowLabel?.text = "\(precipitation)%" // set rain/snow label
                        }
                    
                        if let icon = currentWeather.icon {
                            self.currentWeatherIcon?.image = icon // set the appropriate icon
                        }
                    
                        if let summary = currentWeather.summary {
                            self.summaryLabel?.text = summary // set summary
                        }
                    }
                }
        }
    }
    }
    
    @IBAction func refreshPressed() { // if user pressed refresh...
        locationManager.startUpdatingLocation() // update the location
        getWeather() // get the weather
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool { // function called when user hits return on keyboard
        textField.resignFirstResponder() // get rid of the keyboard
        return true
    }
    
    @IBAction func useCustomCoordinates(sender: AnyObject) {  // function allowing user to enter in their own coordinates, called when they hit use custom coordinates button
        isUsingCustomCoordinates = true
        var customLat = (latTextBox.text as NSString).doubleValue // get the double value from the text box
        var customLon = (lonTextBox.text as NSString).doubleValue // get double value from text box
        self.lat = customLat // set the new latitude
        self.lon = customLon // set the new longitude
        getWeather() // get the weather for the new/custom coordinates
        isUsingCustomCoordinates = false
    }
}

/*---------------------------------------------------------------------------*/
// Helper structs and enum below ---------------------------------------------
/*---------------------------------------------------------------------------*/

struct Forecast {
    
    let APIKeyToUse: String // stores the api key
    let URLwithAPIkey: NSURL? // stores url + apikey
    
    init(APIkeyArg: String) { // initializer/constructor, takes api key as argument
        self.APIKeyToUse = APIkeyArg
        URLwithAPIkey = NSURL(string: "https://api.forecast.io/forecast/\(APIKeyToUse)/")
    }
    
    func getData(lat: Double, lon: Double, completion: (Weather? -> Void)) {
        if let stringToQueryForecastIO = NSURL(string: "\(lat),\(lon)", relativeToURL: URLwithAPIkey) {
            let connection = GetJSON(urlArg: stringToQueryForecastIO)  // create connection to get JSON
            
            connection.downloadJSON { // download the json data
                (let JSONDictionary) in
                let currentWeather = self.loadWeatherFromJSON(JSONDictionary)
                completion(currentWeather)
            }
        }
    }
    
    func loadWeatherFromJSON(jsonDictionary: [String: AnyObject]?) -> Weather? { // helper function used in getData
        if let currentWeatherDictionary = jsonDictionary?["currently"] as? [String: AnyObject] {
            return Weather(weatherDictionary: currentWeatherDictionary) // return weather with correct data in its fields
        } else {
            return nil
        }
    }
}

struct Weather {  // struct to hold weather data
    var temperature: Int?
    var humidity: Int? = 0
    var precipProbability: Int? = 0
    let summary: String?
    var icon: UIImage? = UIImage(named: "default.png")
    
    init(weatherDictionary: [String: AnyObject]) { // initializer/constructor
        temperature = weatherDictionary["temperature"] as? Int // set temperature for later display
        summary = weatherDictionary["summary"] as? String // set the summary for later display
        
        if let humidityDouble = weatherDictionary["humidity"] as? Double {
            self.humidity = Int(humidityDouble * 100) // get int value of the humidity
        }
        if let precipDouble = weatherDictionary["precipProbability"] as? Double {
            precipProbability = Int(precipDouble * 100) // get int value of precip
        }
        
        if let iconString = weatherDictionary["icon"] as? String {
            let weatherIcon: Icon = Icon(rawValue: iconString)!
            icon = weatherIcon.toImage() // set icon value that corresponds to a .png for later display
        }
    }
}

enum Icon: String {  // enum for the icon.  enumerates the possibilities for the icon value, then has toImage() to set it to the right file name for displaying.
    case clearDay = "clear-day"
    case clearNight = "clear-night"
    case Rain = "rain"
    case Snow = "snow"
    case Sleet = "sleet"
    case Wind = "wind"
    case Fog = "fog"
    case Cloudy = "cloudy"
    case PartlyCloudyDay = "partly-cloudy-day"
    case PartlyCloudyNight = "partly-cloudy-night"
    
    func toImage() -> UIImage? { // set imageFileName according to what the value of Icon is
        var imageFileName: String
        
        switch self {
            case .clearDay: imageFileName = "clear-day.png"
            case .clearNight: imageFileName = "clear-night.png"
            case .Rain: imageFileName = "rain.png"
            case .Snow: imageFileName = "snow.png"
            case .Sleet: imageFileName = "sleet.png"
            case .Wind: imageFileName = "wind.png"
            case .Fog: imageFileName = "fog.png"
            case .Cloudy: imageFileName = "cloudy.png"
            case .PartlyCloudyDay: imageFileName = "cloudy-day.png"
            case .PartlyCloudyNight: imageFileName = "cloudy-night.png"
        }
        return UIImage(named: imageFileName)
    }
}