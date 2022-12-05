//
//  UITextFieldExtensions.swift
//  photoPicker
//
//  Created by Елизавета Хворост on 17/11/2022.
//

import UIKit

extension UITextField
{
    func inputAccessoryViewSecure()
    {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        view.backgroundColor = .systemBackground
        let button = UIButton(frame: CGRect(x: view.bounds.width - 80, y: 0, width: 80, height: view.bounds.height))
        let image = UIImage(systemName: "eye.slash")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(toogleSecure(_:)), for: .touchUpInside)
        view.addSubview(button)
        self.inputAccessoryView = view
    }
    
    @objc private func toogleSecure(_ sender: UIButton)
    {
        self.isSecureTextEntry.toggle()
        let image = UIImage(systemName: self.isSecureTextEntry ? "eye.slash" : "eye")
        sender.setImage(image, for: .normal)
    }
}
