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
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let faceIDManager = FaceIDManager()
    private var imageDataSource = [UIImage]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let savedImages = self.getSavedImages()
        {
            self.imageDataSource.append(contentsOf: savedImages)
        }
        self.collectionView.register(UINib(nibName: "ItemCollectionViewCell", bundle: nil),
                                     forCellWithReuseIdentifier: "ItemCollectionViewCell")
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
        alertController.addAction(UIAlertAction(title: "From URL", style: .default, handler: { [weak self] action in
            self?.showURLPicker()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alertController, animated: true)
    }
    
    private func showURLPicker()
    {
        let alertController = UIAlertController(title: "Past URL here",
                                                message: "Copy image URL from Safari",
                                                preferredStyle: .alert)
        
        let upload = UIAlertAction(title: "Upload",
                                   style: .default) { [weak self] (_) in
            if let urlString = alertController.textFields?.first?.text, let url = URL(string: urlString)
            {
                self?.downloadFrom(url: url)
            }
            else
            {
                self?.showAlert("Wrong URL")
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        //eye, eye.slash
        alertController.addTextField { (textField) in
            textField.placeholder = "Image URL"
            textField.textAlignment = .center
        }
        alertController.addAction(upload)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
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
        let fileName = NSUUID().uuidString + ".jpg"
        guard let filePath = directory.appendingPathComponent(fileName) else {
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
    
    func getSavedImages() -> [UIImage]?
    {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        {
            do
            {
                let fileURLS = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                if fileURLS.count > 0
                {
                    var images = [UIImage]()
                    for eachURL in fileURLS
                    {
                        if eachURL.absoluteString.hasSuffix(".jpg"), let last = eachURL.pathComponents.last
                        {
                            if let image = UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(last).path)
                            {
                                images.append(image)
                            }
                        }
                    }
                    return images
                }
            }
            catch
            {
                print(error)
            }
        }
        return nil
    }
    
    private func downloadFrom(url: URL)
    {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        let session = URLSession(configuration: .default).dataTask(with: urlRequest) { data, _, _ in
            if let imageData = data, let image = UIImage(data: imageData)
            {
                DispatchQueue.main.async { [weak self] in
                    self?.imageDataSource.append(image)
                    _ = self?.saveImage(image: image)
                    self?.collectionView.reloadData()
                }
            }
        }
        session.resume()
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
    
    private func showImage(_ image: UIImage)
    {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImageViewController") as? ImageViewController
        {
            vc.image = image
            self.present(vc, animated: true)
        }
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
                            self?.imageDataSource.append(firstImage)
                            _ = self?.saveImage(image: firstImage)
                            self?.collectionView.reloadData()
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
        self.imageDataSource.append(image)
        _ = self.saveImage(image: image)
        self.collectionView.reloadData()
    }
}

extension ViewController: UICollectionViewDataSource
{
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.imageDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCollectionViewCell", for: indexPath) as! ItemCollectionViewCell
        if self.imageDataSource.count > indexPath.row
        {
            let image = self.imageDataSource[indexPath.row]
            cell.photoImageView.image = image
        }
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if self.imageDataSource.count > indexPath.row
        {
            let image = self.imageDataSource[indexPath.row]
            self.showImage(image)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let width: CGFloat = (UIScreen.main.bounds.width - 3) / 3.0
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    {
        return 1
    }
}

