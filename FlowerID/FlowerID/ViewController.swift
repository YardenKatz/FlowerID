//
//  ViewController.swift
//  FlowerID
//
//  Created by Yarden Katz on 24/06/2021.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController {

    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var bgImageView: UIImageView!
    
    let picker = UIImagePickerController()
    var pickedImage: UIImage?
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.delegate = self
        picker.sourceType = .camera
        picker.allowsEditing = true
    }

    @IBAction func didPressCamera(_ sender: Any) {
        present(picker, animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier(configuration: MLModelConfiguration()).model) else {
            fatalError("Cannot import model")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image.")
            }
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]

        AF.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { response in
            switch response.result {
            case .success:
                
                let flowerJSON: JSON = JSON(response.value ?? "")
                print(flowerJSON)
                let pageId = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageId]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                
                self.descriptionLbl.text = flowerDescription
                self.bgImageView.sd_setImage(with: URL(string: flowerImageURL))
                
            case let .failure(error):
                print(error)
            }
        }
    }
}

// MARK:- UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.originalImage] as? UIImage else { return }
        guard let ciImage = CIImage(image: image) else {
            fatalError("Could not convert image to CIIImage.")
        }
        
        pickedImage = image
        detect(image: ciImage)
    }
}

