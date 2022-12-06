//
//  ImageViewController.swift
//  photoPicker
//
//  Created by Елизавета Хворост on 06/12/2022.
//

import UIKit

class ImageViewController: UIViewController
{
    @IBOutlet weak var imageView: UIImageView!
    var image: UIImage?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.imageView.image = self.image
    }
}
