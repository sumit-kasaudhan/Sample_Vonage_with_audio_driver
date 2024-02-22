//
//  ViewController.swift
//  Custom-Audio-Driver
//
//  Created by Roberto Perez Cubero on 11/08/16.
//  Copyright © 2016 tokbox. All rights reserved.
//

import UIKit
import OpenTok

let kWidgetHeight = 240
let kWidgetWidth = 320

// *** Fill the following variables using your own Project info  ***
// ***            https://tokbox.com/account/#/                  ***
// Replace with your OpenTok API key
let kApiKey = "47342481"
// Replace with your generated session ID
let kSessionId = "1_MX40NzM0MjQ4MX5-MTcwODU5ODAzNjc2MX4wSGVxWXVXZ2h1T3pxcmVNWkVyNldGZUN-UH5-"
// Replace with your generated token
let kToken = "T1==cGFydG5lcl9pZD00NzM0MjQ4MSZzaWc9M2UyMTAzYWE3M2VmOTFjYTcxNzg4OGIzZmNmNjk2ZWE4NTMyZWYxNDpzZXNzaW9uX2lkPTFfTVg0ME56TTBNalE0TVg1LU1UY3dPRFU1T0RBek5qYzJNWDR3U0dWeFdYVlhaMmgxVDNweGNtVk5Xa1Z5TmxkR1pVTi1VSDUtJmNyZWF0ZV90aW1lPTE3MDg1OTgwNzMmbm9uY2U9MC43NTA5ODQ0MDI1MTYzNjc5JnJvbGU9cHVibGlzaGVyJmV4cGlyZV90aW1lPTE3MDg2MDM0NzMmY29ubmVjdGlvbl9kYXRhPSU3QiUyMnNlc3Npb25JZCUyMiUzQSUyMjFfTVg0ME56TTBNalE0TVg1LU1UY3dPRFU1T0RBek5qYzJNWDR3U0dWeFdYVlhaMmgxVDNweGNtVk5Xa1Z5TmxkR1pVTi1VSDUtJTIyJTJDJTIyYXVkaW9sb2dpc3RJZCUyMiUzQSUyMjk0NzFmOTViLTFiYzQtNDFkMS1hZTQ2LTA1NGQ5YjE3ZGJiYiUyMiUyQyUyMm1vYmlsZVVzZXJJZCUyMiUzQSUyMjNiMTJkNDY3LWIzNGQtNGIyNi1iNTQ5LWZmNWRkNTM4MzA1MiUyMiUyQyUyMnBhcnRpY2lwYW50VHlwZSUyMiUzQSUyMlBhdGllbnQlMjIlN0QmaW5pdGlhbF9sYXlvdXRfY2xhc3NfbGlzdD0="


class ViewController: UIViewController {
    @IBAction func mutePressed(_ sender: Any) {
        publisher?.publishAudio = false
    }
    @IBAction func unMutePressed(_ sender: Any) {
        publisher?.publishAudio = true
    }
    lazy var session: OTSession = {
        return OTSession(apiKey: kApiKey, sessionId: kSessionId, delegate: self)!
    }()
    
    var publisher: OTPublisher?
    var subscriber: OTSubscriber?
    let customAudioDevice = DefaultAudioDevice()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        OTAudioDeviceManager.setAudioDevice(customAudioDevice)
        doConnect()
    }
    
    /**
     * Asynchronously begins the session connect process. Some time later, we will
     * expect a delegate method to call us back with the results of this action.
     */
    private func doConnect() {
        var error: OTError?
        defer {
            process(error: error)
        }        
        session.connect(withToken: kToken, error: &error)
    }
    
    /**
     * Sets up an instance of OTPublisher to use with this session. OTPubilsher
     * binds to the device camera and microphone, and will provide A/V streams
     * to the OpenTok session.
     */
    fileprivate func doPublish() {
        var error: OTError? = nil
        defer {
            process(error: error)
        }
        let settings = OTPublisherSettings()
        settings.name = UIDevice.current.name
        publisher = OTPublisher(delegate: self, settings: settings)
        if let pub = publisher, let pubView = pub.view {
            session.publish(pub, error: &error)
            pubView.frame = CGRect(x: 0, y: 0, width: kWidgetWidth, height: kWidgetHeight)
            view.addSubview(pubView)
        }
    }
    
    fileprivate func doSubscribe(_ stream: OTStream) {
        var error: OTError?
        defer {
            process(error: error)
        }
        subscriber = OTSubscriber(stream: stream, delegate: self)
        session.subscribe(subscriber!, error: &error)
    }
    
    fileprivate func process(error err: OTError?) {
        if let e = err {
            showAlert(errorStr: e.localizedDescription)
        }
    }
    
    fileprivate func showAlert(errorStr err: String) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(controller, animated: true, completion: nil)
        }
    }
}

// MARK: - OTSession delegate callbacks
extension ViewController: OTSessionDelegate {
    func sessionDidConnect(_ session: OTSession) {
        print("Session connected")        
        doPublish()
    }
    
    func sessionDidDisconnect(_ session: OTSession) {
        print("Session disconnected")
    }
    
    func session(_ session: OTSession, streamCreated stream: OTStream) {
        print("Session streamCreated: \(stream.streamId)")
        doSubscribe(stream)
    }
    
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        print("Session streamDestroyed: \(stream.streamId)")
        if let subStream = subscriber?.stream, subStream.streamId == stream.streamId {
            subscriber?.view?.removeFromSuperview()
        }
    }
    
    func session(_ session: OTSession, didFailWithError error: OTError) {
        print("session Failed to connect: \(error.localizedDescription)")
    }
    
}

// MARK: - OTPublisher delegate callbacks
extension ViewController: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        print("Publishing")
    }
    
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
    }
    
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        print("Publisher failed: \(error.localizedDescription)")
    }
}

// MARK: - OTSubscriber delegate callbacks
extension ViewController: OTSubscriberDelegate {
    func subscriberDidConnect(toStream subscriberKit: OTSubscriberKit) {
        subscriber?.view?.frame = CGRect(x: 0, y: kWidgetHeight, width: kWidgetWidth, height: kWidgetHeight)
        if let subsView = subscriber?.view {
            view.addSubview(subsView)
        }
    }
    
    func subscriber(_ subscriber: OTSubscriberKit, didFailWithError error: OTError) {
        print("Subscriber failed: \(error.localizedDescription)")
    }
    
    func subscriberVideoDataReceived(_ subscriber: OTSubscriber) {
    }
}

