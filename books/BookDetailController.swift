//
//  BookDetailController.swift
//  books
//
//  Created by Oliver on 10/10/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import UIKit

class BookDetailController: UIViewController {
    var bookId: String?
    
    @IBOutlet weak var summaryViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var descriptionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var bookDescription: UILabel!
    @IBOutlet weak var bookTitle: UILabel!
    @IBOutlet weak var bookImage: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var summaryView: UIView!
    
    @IBOutlet weak var descriptionView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let id = self.bookId {
            print(id)
            self.loadDetails(id: id)
            self.loadImage(id: id)
        }

        // Do any additional setup after loading the view.
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.main.async {
            self.resizeViews()
        }
    }
    
    func resizeViews() {
        self.summaryViewHeight.constant = self.bookImage.frame.height + 16
        self.descriptionViewHeight.constant = self.bookDescription.frame.height + 16
        let frameHeight = self.summaryViewHeight.constant + self.descriptionViewHeight.constant + 25
        let size = CGSize(width: self.contentView.frame.width, height: frameHeight)
        self.contentView.frame.size = size
        self.scrollView.contentSize = size
        self.summaryView.sizeToFit()
    }
    
    func formatDescription(description: String) -> NSAttributedString {
        let data = description.data(using: String.Encoding.unicode)! // mind "!"
        return try! NSAttributedString( // do catch
            data: data,
            options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil)
        
    }
    
    func formatDate(date: Date?) -> String {
        if date != nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            return dateFormatter.string(from: date!)
        } else {
            return "Not available"
        }
    }
    
    func loadDetails(id: String) {
        try? Books.sharedInstance.getDetails(withID: id, { (bookDetails) in
            DispatchQueue.main.async {
                var bookSummary = bookDetails.title ?? "Title not available"
                bookSummary += "\n\nPublished: " + self.formatDate(date: bookDetails.publicationDate)
                bookSummary += "\nISBN: " + (bookDetails.ISBN ?? "Not available")
                
                if let title = bookDetails.title {
                    self.title = title
                }
                
                self.bookTitle.text = bookSummary
                self.bookDescription.attributedText = self.formatDescription(description: bookDetails.description ?? "Description not available")
                
                DispatchQueue.main.async {
                    self.resizeViews()
                }
            }
        })
    }
    
    func loadImage(id: String) {
        try? Books.sharedInstance.getImage(withID: id, { (data) in
            DispatchQueue.main.async {
                self.bookImage.image = UIImage(data: data)
            }
        })
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
