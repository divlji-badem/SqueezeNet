//
//  ViewController.swift
//  SqueezeNet
//
//  Created by Jelena Tasic on 28.10.21..
//

import UIKit
import Vision
import CoreML
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
    }
    
    //MARK:- UIImagePickerControllerDelegate Methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            
            guard let ciImage = CIImage(image: pickedImage) else {
                fatalError("Could not convert UIimage into CIImage.")
            }
            detect(image: ciImage)
            // imageView.image = pickedImage
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }

    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: SqueezeNet(configuration: .init()).model) else {
            fatalError("Loading CoreML Model Failed.")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed to process image")
            }
            if let firstResult = results.first {
                let identifier = firstResult.identifier
                self.navigationItem.title = identifier.capitalized + " " + String(format: "%.2f", firstResult.confidence)
                self.infoRequest(title: identifier.components(separatedBy: ",")[0])
            }
           //print(results)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do{
            try handler.perform([request])
        }
        catch {
            print(error)
        }
    }
    @IBAction func cameraButtonTapped(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func infoRequest(title: String){
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : title,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500",
        ]
        AF.request(wikipediaURl, parameters: parameters).responseJSON { response in
            if let safeData = response.data {
                let json: JSON = JSON(safeData)
                let pageId = json["query"]["pageids"][0].stringValue
                let extract = json["query"]["pages"][pageId]["extract"].stringValue
                let imageUrl = json["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: imageUrl))
                self.label.text = extract
                print(json)
            }
        }
    }
}

