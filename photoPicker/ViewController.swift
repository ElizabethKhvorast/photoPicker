//
//  ViewController.swift
//  photoPicker
//
//  Created by Елизавета Хворост on 17/11/2022.
//

import UIKit
import PhotosUI

class ViewController: UIViewController
{
    @IBOutlet weak var imageView: UIImageView!
    
    private let fileName = "image.jpg"
    private let faceIDManager = FaceIDManager()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let savedImage = self.getSavedImage(named: self.fileName)
        {
            self.imageView.image = savedImage
        }
        //setup default password to have access for library
        if UserDefaults.standard.string(forKey: "admin password") == nil
        {
            UserDefaults.standard.set("1234", forKey: "admin password")
        }
    }
    
    @IBAction func pickPhoto(_ sender: Any)
    {
        self.showAlert()
    }
    
    private func showOptions()
    {
        let alertController = UIAlertController(title: "Pick Photo", message: "Choose the source", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] action in
            self?.showCameraPicker()
        }))
        alertController.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] action in
            self?.showPhotoPicker()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alertController, animated: true)
    }
    
    private func showPhotoPicker()
    {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    private func showCameraPicker()
    {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.allowsEditing = true
        vc.delegate = self
        self.present(vc, animated: true)
    }
    
    private func useFaceID()
    {
        self.faceIDManager.canEvaluate { [weak self] canEvaluate, type, error in
            guard canEvaluate else {
                self?.showAlert(error?.errorDescription)
                return
            }
            self?.faceIDManager.evaluate(completion: { [weak self] success, error in
                guard success else {
                    if error == .userFallback
                    {
                        self?.showAlert()
                    }
                    else
                    {
                        self?.showAlert(error?.errorDescription)
                    }
                    return
                }
                self?.showOptions()
            })
        }
    }
    
    func saveImage(image: UIImage) -> Bool
    {
        guard let data = image.jpegData(compressionQuality: 1) else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
            return false
        }
        guard let filePath = directory.appendingPathComponent(self.fileName) else {
            return false
        }
        do
        {
            try data.write(to: filePath)
            return true
        }
        catch
        {
            print(error.localizedDescription)
            return false
        }
    }
    
    func getSavedImage(named: String) -> UIImage?
    {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    func showAlert()
    {
        let alertController = UIAlertController(title: "Admin Password",
                                                message: "Please input admin password",
                                                preferredStyle: .alert)
        let faceIDAction = UIAlertAction(title: "Use FaceID",
                                         style: .default) { [weak self] (_) in
            self?.useFaceID()
        }
        let enable = UIAlertAction(title: "Enable",
                                   style: .default) { [weak self] (_) in
            let field = alertController.textFields?.first?.text
            if let x = UserDefaults.standard.string(forKey: "admin password"), x == field
            {
                self?.showOptions()
            }
            else
            {
                self?.showAlert("Wrong password!")
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        //eye, eye.slash
        alertController.addTextField { (textField) in
            textField.placeholder = "Admin Password"
            textField.isSecureTextEntry = true
            textField.keyboardType = .numberPad
            textField.textAlignment = .center
            //make button to enable & disable secure mode
            textField.inputAccessoryViewSecure()
        }
        alertController.addAction(faceIDAction)
        alertController.addAction(enable)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showAlert(_ message: String?)
    {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}

extension ViewController: PHPickerViewControllerDelegate
{
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult])
    {
        picker.dismiss(animated: true)
        if let firstItemProvider = results.first?.itemProvider
        {
            if firstItemProvider.canLoadObject(ofClass: UIImage.self)
            {
                firstItemProvider.loadObject(ofClass: UIImage.self) { image, error  in
                    if let firstImage = image as? UIImage
                    {
                        DispatchQueue.main.async {  [weak self] in
                            self?.imageView.image = firstImage
                            _ = self?.saveImage(image: firstImage)
                        }
                    }
                }
            }
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        picker.dismiss(animated: true)
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            return
        }
        self.imageView.image = image
        _ = self.saveImage(image: image)
    }
}

