//
//  ViewController.swift
//  SeeFood
//
//  Created by AmirReza Jamali on 2/25/23.
//

import UIKit
import CoreML

import PhotosUI
import Vision
class ViewController: UIViewController {
    
    @IBOutlet weak var mainImageView: UIImageView!
    let imagePicker = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
    }
    func openPicker() {
        var imagePickerConfiguration = PHPickerConfiguration(photoLibrary: .shared())
        imagePickerConfiguration.selectionLimit = 1
        imagePickerConfiguration.filter = PHPickerFilter.any(of: [.images, .livePhotos])
        let pickerVC = PHPickerViewController(configuration: imagePickerConfiguration)
        pickerVC.delegate = self
        present(pickerVC,animated: true)
    }
    
    
    @IBAction func takePhotoUsingCamera(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true,completion: nil)
    }
    @IBAction func pickPhotoFromPhotoLibrary(_ sender: UIBarButtonItem) {
        openPicker()
    }
    func detectThePhoto(_ photo: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: Inceptionv3(configuration: MLModelConfiguration()).model) else {
            fatalError("Loading coreML model fail")
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Modle failed to process image.")
            }
            if let firstResult = results.first {
                self.navigationItem.title = firstResult.identifier
            }
        }
        let handler = VNImageRequestHandler(ciImage: photo)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        results.forEach { result in
            result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
                guard let userPickedImage = reading as? UIImage , error == nil else {
                    fatalError("Error picking image")
                }
                DispatchQueue.main.async {
                    self.mainImageView.image = userPickedImage
                    guard let ciImage = CIImage(image: userPickedImage) else {
                        fatalError("Unable to convert UI Image to CI Image")
                    }
                    self.detectThePhoto(ciImage)
                }
            }
        }
    }
    
    
    
}


extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("Error downcasting selected photo from camera")
        }
        mainImageView.image = userPickedImage
        imagePicker.dismiss(animated: true)
        guard let ciImage = CIImage(image: userPickedImage) else {
            fatalError("Unable to convert UI Image to CI Image")
        }
        detectThePhoto(ciImage)
    }
    
}

extension ViewController: UINavigationControllerDelegate {
    
}
