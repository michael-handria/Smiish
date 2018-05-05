//
//  ChatViewController.swift
//  Smiish
//
//  Created by Michael Handria on 3/26/18.
//  Copyright © 2018 Michael Handria. All rights reserved.
//

import UIKit
import UserNotifications
import Toaster

//struct to hold the message data coming in
struct Messages{
    var name: String
    var message: String
    var systemTime: String

    init(name: String, message: String, systemTime: String){
        self.name = name
        self.message = message
        self.systemTime = systemTime
    }
}

class ChatViewController: UIViewController{

    //holds the app user's data of roomname that
    //he/she is in and the username he/she selected
    var userName: String = ""
    var roomName: String = ""
    open static var messageBadge: Int = 0

    let center = UNUserNotificationCenter.current()
    let notification = UNMutableNotificationContent()

    var messages = [Messages]()

    @IBOutlet weak var sendButton: UIButton!
    //@IBOutlet weak var msgContent: ChatField!
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var msgContent: ChatField!



    /* CONSTRUCTOR
     summary:
        custom custroctor for this specific controller
        (empty for now can be overloaded for later implementation if necessary)
    */
    init(){
        super.init(nibName: nil, bundle: nil)
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    override func viewDidAppear(_ animated: Bool) {
        ChatViewController.messageBadge = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //reset badge for notifications
        ChatViewController.messageBadge = 0



        let rightSwipeBack = UISwipeGestureRecognizer(target: self, action: #selector(ChatViewController.goBack))
        rightSwipeBack.direction = .right


        tableView.addGestureRecognizer(rightSwipeBack)


        //Call StyleView Func
        styleViews()

        //Call standardLayout Func
        standardLayout()


        //give table delegate.
        //basically allows the tableView utilize the
        //extension code written below
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none


        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard))
        tableView.addGestureRecognizer(tap)


        //socket event
        Socket.default.socket.on("chat message") { (data, ack) in
            if let dict = data[0] as? Dictionary<String, String>{
                if let name = dict["username"], let time = dict["systemTime"], let msg = dict["message"]{
                     self.insertMsgArray(name: name, time: time, msg: msg)
                }
            }
        }

        Socket.default.socket.on("user join") { (data, ack) in
            var userName = "you"
            if data.count > 2 {
                userName = data[1] as! String
            }
            let broadcast = userName+" has joined the room"
            Toast(text: broadcast).show()
        }
        // Do any additional setup after loading the view.
    }

    /*
     summary:
        this function will be used to dismiss the keyboard from the view
    */
    @objc override func dismissKeyboard() {
        view.endEditing(true)
        tableView.reloadData()
    }

    /*
     summary:
        function is called as a swipe left gesture
        this will pop the current view and bring user to
        the last view before going to this view
        -> basically a go back button
     params:
        sender - swipe left gesture.
    */
    @objc func goBack(sender: UISwipeGestureRecognizer){
        self.navigationController?.popViewController(animated: true)
    }

    /*
     summary:
        function will insert new message to the array and
        send reload table view as well as scroll to the last, newly added, cell
        of the table view
     params:
        name - username that sent the msg
        msg - content to be displayed "user message"
    */
    func insertMsgArray(name: String, time: String, msg: String){



        //append on the message array when the user sends a message
        messages.append(Messages(name: name, message: msg, systemTime: time))

        //table must be reloaded in order to show the incomming data.
        tableView.reloadData()

        //function to notify users
        notifyUsers(name: (name+" "+time), msg: msg)

        //perform this ASYNCRONOUSLY to scroll to the last cell that has just been added in.
        DispatchQueue.main.async {
            //get an index path (last row) then scroll to bottom of added msg.
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    /*
     summary:
        function will notify users, if users enters app in background mode, that a notification
        is comming in
     params:
        name - username
        msg - text content to notify the user with.
     */
    func notifyUsers(name: String, msg: String){
        let status = UIApplication.shared.applicationState
        if status.rawValue == 2{
            ChatViewController.messageBadge = ChatViewController.messageBadge + 1
            notification.title = name
            notification.body = msg
            notification.badge = NSNumber(value: ChatViewController.messageBadge)
            notification.sound = UNNotificationSound.default()
            let request = UNNotificationRequest(identifier: "user notify", content: notification, trigger: nil)
            center.add(request)
        }
    }

    /*
     Generated by Xcode
    */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
     summary:
        function called when app user press the send button to "emit" the message.
     params:
        sender - UIButtonView that calls this function
    */
    @IBAction func sendMsg(_ sender: UIButton) {
        Socket.default.socket.emit("chat message", msgContent.text)
        msgContent.text = ""
        //view.endEditing(true)
    }

    /* StyleViews

        Add Style to VC

    */
    private func styleViews(){

        //tableView.backgroundColor = .yellow

        sendButton.layer.cornerRadius = 12
        sendButton.titleLabel?.font = UIFont(name: "Pacifico-Regular", size: 15)


    }

    /* standardLayout func

        Func called to add constraints within the VC

    */
    private func standardLayout(){

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: msgContent.topAnchor, constant: -10).isActive = true
        //tableView.contentMode = .scaleAspectFit

        //Msg Content Constraints
        msgContent.translatesAutoresizingMaskIntoConstraints = false
        msgContent.heightAnchor.constraint(equalToConstant: 30).isActive = true
        msgContent.leadingAnchor.constraint(equalTo: view.leadingAnchor , constant: 10).isActive = true
        msgContent.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10).isActive = true
        msgContent.topAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
        msgContent.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 75).isActive = true
        sendButton.leftAnchor.constraint(equalTo: msgContent.rightAnchor).isActive = true
        sendButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10).isActive = true
        sendButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 5).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true

    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource{

    //number of sections that the table will have.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    //get the count of the cells into the table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        //get current message data to be displayed on the table
        let messageNew = self.messages[indexPath.row]

        //a boolean that can determine whether or not the
        //last message added to the table is sent by the current message
        //to be displayed
        var displayName = (indexPath.row == 0)
        if(indexPath.row > 0){
            displayName = (self.messages[indexPath.row-1].name != messageNew.name)
        }
        let content = messageNew.systemTime + "\n" + messageNew.message
        //determine what type of cell will go into the table view
        if(displayName){
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellView", for: indexPath) as! MessageCellWithName
            cell.setCell(name: messageNew.name, msg: content, senderName: self.userName)
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "CellViewNoName", for: indexPath) as! MessageCellNoName
            cell.setCell(name: messageNew.name, msg: content, senderName: self.userName)
            return cell
        }
    }
}
