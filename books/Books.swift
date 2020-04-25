//
//  Books.swift
//  books
//
//  Created by Oliver on 10/10/2018.
//  Copyright © 2018 Oliver Bell. All rights reserved.
//

import Foundation

struct Book {
    var title: String?
    var author: String?
    var id: String
}

struct BookDetails {
    var title: String?
    var author: String?
    var description: String?
    var publicationDate: Date?
    var ISBN: String?
}

enum JSONError: Error {
    case InvalidURL(String)
    case InvalidKey(String)
    case InvalidArray(String)
    case InvalidData
    case InvalidImage
    case indexOutOfRange
    
}

class Books {
    public static let sharedInstance = Books()
    
    private static let BOOKS_URL = "https://www.googleapis.com/books/v1/volumes"
    private static let BOOK_QUERY_TEMPLATE = [
        URLQueryItem(name: "maxResults", value: "40"),
        URLQueryItem(name: "fields", value: "items(id,volumeInfo(title,authors,publishedDate))")
    ]
    
    private static let BOOK_IMAGE_URL = "https://books.google.com/books/content"
    //?printsec=frontcover&img=1&source=gbs_api
    private static let BOOK_IMAGE_QUERY_TEMPLATE = [
        URLQueryItem(name: "printsec", value: "frontcover"),
        URLQueryItem(name: "img", value: "1"),
        URLQueryItem(name: "source", value: "gbs_api")
    ]
    
    var searchData: [Book]
    
    private init() {
        searchData = []
    }
    
    public func getBook(atIndex index: Int) throws -> Book {
        return self.searchData[index]
    }
    
    public var count: Int {
        get {
            return searchData.count;
        }
    }
    
    public func search(withText text: String, _ completion: @escaping ()->()) throws {
        let session = URLSession.shared
        
        // Generate the query for this text
        var query = Books.BOOK_QUERY_TEMPLATE
        query.append(URLQueryItem(name: "q", value: text))
        
        guard let booksUrl = NSURLComponents(string: Books.BOOKS_URL) else {
            throw JSONError.InvalidURL(Books.BOOKS_URL)
        }
        
        booksUrl.queryItems = query
        
        // Generate the query url from the query items
        let url = booksUrl.url!
        
        session.dataTask(with: url, completionHandler: {(data, response, error) -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! [String: AnyObject]
                guard let items = json["items"] as! [[String: Any]]? else {
                    throw JSONError.InvalidArray("items")
                }
                
                self.searchData = []
                
                for item in items {
                    guard let id = item["id"] as! String? else {
                        throw JSONError.InvalidKey("id")
                    }
                    
                    guard let volumeInfo = item["volumeInfo"] as! [String: AnyObject]? else {
                        throw JSONError.InvalidKey("volumeInfo")
                    }
                    
                    let title = volumeInfo["title"] as? String ?? "Title not available"
                    
                    var authors = "No author information"
                
                    if let authorsArray = volumeInfo["authors"] as! [String]? {
                        authors = authorsArray.joined(separator: ", ")
                    }
                    
                    let book = Book(title: title, author: authors, id: id)
                    
                    self.searchData.append(book)
                }
                
            } catch  {
                print("Error thrown: \(error)")
            }
            completion()
        }).resume()
    }
    
    public func getDetails(withID id: String, _ completion: @escaping (BookDetails)->()) throws {
        let session = URLSession.shared
        
        guard let bookUrl = NSURLComponents(string: Books.BOOKS_URL + "/" + id) else {
            throw JSONError.InvalidURL(Books.BOOKS_URL)
        }
        
        print(bookUrl)
        
        session.dataTask(with: bookUrl.url!, completionHandler: {(data, response, error) -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! [String: AnyObject]
                guard let info = json["volumeInfo"] as! [String: Any]? else {
                    throw JSONError.InvalidArray("volumeInfo")
                }
                
                let title = info["title"] as? String ?? "Title not available"
                
                var authors: String? = nil
                
                if let authorsArray = info["authors"] as! [String]? {
                    authors = authorsArray.joined(separator: ", ")
                }
                
                let description = info["description"] as? String ?? "Description not available"
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
                
                var pubDate: Date? = nil
                if let dateString = info["publishedDate"] as! String? {
                    print(dateString)
                    pubDate = dateFormatter.date(from: dateString)
                }
                
                var isbn: String? = nil
                if let isbns = info["industryIdentifiers"] as! [[String: Any]]? {
                    for isbnObject in isbns {
                        if let isbnType = isbnObject["type"] as! String? {
                            if isbnType == "ISBN_10" {
                                isbn = isbnObject["identifier"] as? String ?? "N/A"
                                break
                            }
                        }
                    }
                }
                
                completion(BookDetails(title: title, author: authors, description: description, publicationDate: pubDate, ISBN: isbn))
            } catch {
                print("Error thrown: \(error)")
            }
        }).resume()
    }
    
    public func getImage(withID id: String, _ completion: @escaping (Data)->()) throws {
        guard let bookUrl = NSURLComponents(string: Books.BOOK_IMAGE_URL) else {
            throw JSONError.InvalidURL(Books.BOOK_IMAGE_URL)
        }
        
        var query = Books.BOOK_IMAGE_QUERY_TEMPLATE
        query.append(URLQueryItem(name: "id", value: id))
        
        bookUrl.queryItems = query
        
        DispatchQueue.global(qos: .background).async {
            let data = try? Data(contentsOf: bookUrl.url!)
            completion(data!)
        }
    }
}
