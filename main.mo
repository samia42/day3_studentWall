import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Blob "mo:base/Blob";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Order "mo:base/Order";
import Array "mo:base/Array";
actor {

  public type Content = {
    #Text : Text;
    #Image : Blob;
    #Video : Blob;
  };
  type Message = {
    creator : Principal;
    vote : Int;
    content : Content;
  };

  var messageId : Nat = 0;

  var wall = HashMap.HashMap<Nat, Message>(1, Nat.equal, func(x) { Text.hash(Nat.toText(x)) });

  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    let mId = messageId;
    messageId += 1;
    let newMessage = {
      vote = 0;
      content = c;
      creator = caller;
    };
    wall.put(mId, newMessage);

    return mId;
  };

  //Get a specific message by ID
  public query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    switch (wall.get(messageId)) {
      case null #err("No message");
      case (?message) {
        return #ok message;
      };
    };
  };
  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    switch (wall.get(messageId)) {
      case (null) {
        #err("invalid id");
      };
      case (?currentMessage) {
        if (Principal.equal(currentMessage.creator, caller)) {
          let updateMessage = {
            content = c;
            vote = currentMessage.vote;
            creator = caller;
          };
          wall.put(messageId, updateMessage);
        } else {
          return #err "Invalid caller";
        };

        #ok;
      };
    };
  };

  //Delete a specific message by ID
  public func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    switch (wall.remove(messageId)) {
      case (null) { return #err("id doesnot exist") };
      case (_) {
        #ok;

      };
    };
  };
  // Voting
  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    switch (wall.get(messageId)) {
      case (null) {
        #err("No message with this id");
      };
      case (?currentMessage) {
        let updateMessage = {
          content = currentMessage.content;
          vote = currentMessage.vote +1;
          creator = currentMessage.creator;
        };
        wall.put(messageId, updateMessage);
        #ok;
      };
    };
  };
  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    switch (wall.get(messageId)) {
      case (null) {
        #err("No message with this id");
      };
      case (?currentMessage) {
        let updateMessage = {
          content = currentMessage.content;
          vote = currentMessage.vote - 1;
          creator = currentMessage.creator;
        };
        wall.put(messageId, updateMessage);
        #ok;
      };
    };
  };

  //Get all messages
  public query func getAllMessages() : async [Message] {
    let buffer = Buffer.Buffer<Message>(1);
    for (value in wall.vals()) {
      buffer.add(value);
    };
    let arr = Buffer.toArray(buffer);
    return arr;
  };

  //compare func
  private func compare(m1 : Message, m2 : Message) : Order.Order {
    switch (Int.compare(m1.vote, m2.vote)) {
      case (#greater) return #less;
      case (#less) return #greater;
      case (_) return #equal;
    };
  };
  //Get all messages
  public query func getAllMessagesRanked() : async [Message] {
    let buffer = Buffer.Buffer<Message>(1);
    for (value in wall.vals()) {
      buffer.add(value);
    };
    let arr = Buffer.toArray(buffer);
    Array.sort<Message>(arr, compare);
  };
};
