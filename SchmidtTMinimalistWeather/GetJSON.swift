//  GetJSON.swift
//  SchmidtTMinimalistWeather
//
//  Created by terry schmidt on 5/31/15.
//  Copyright (c) 2015 terry schmidt. All rights reserved.
//
//  Terry Schmidt, June 2015, CSC 471, Final Project

import Foundation

// class responsibility: download some JSON
// NSURLSession API is ASYNC (yay!)
class GetJSON {
    var setup = NSURLSessionConfiguration.defaultSessionConfiguration() // set the configuration
    lazy var makeSession: NSURLSession = NSURLSession(configuration: self.setup) // create session
    var queryString: NSURL // variable to hold the string that will be used to query forecast.io
    
    init(urlArg: NSURL) { // initializer/constructor
        self.queryString = urlArg
    }
    
    typealias JSONDictionaryCompletion = ([String: AnyObject]?) -> Void
    // typealias: alternate name for a type (helps readability)
    
    func downloadJSON(completion: JSONDictionaryCompletion) { // always returns a dictionary [String: AnyObject]
        let requestToSend: NSURLRequest = NSURLRequest(URL: queryString)
        let task = makeSession.dataTaskWithRequest(requestToSend) {
            (let data, let response, let error) in // trailing closure
            //println(data)
            println("Background thread println")
            
            // Check HTTP response (200 is success)
            if let httpReplyFromForecastIO = response as? NSHTTPURLResponse {
                switch(httpReplyFromForecastIO.statusCode) { // first check HTTP reply for success code
                    // case 200 is success.  when successful, we make a dictionary of the json data
                    case 200:
                    let jsonDictionary = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as? [String: AnyObject] // convert data object to JSON dictionary
                    completion(jsonDictionary)
                    
                    default: println("Request sent to forecast.io was not successful.") // everything other than success code 200 is bad
                }
            }
        }
        println("Main thread println")
        task.resume() // task is added to the session, and made active when we call resume.  Carried out on a background thread.
    }
}