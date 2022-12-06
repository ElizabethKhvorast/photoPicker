//
//  ItemCollectionViewCell.swift
//  photoPicker
//
//  Created by Елизавета Хворост on 06/12/2022.
//

import UIKit

class ItemCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        self.clearCell()
    }
    
    override func prepareForReuse()
    {
        super.prepareForReuse()
        self.clearCell()
    }
    
    private func clearCell()
    {
        self.photoImageView.image = nil
    }
}
