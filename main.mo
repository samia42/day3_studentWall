actor {
  public func greet(name : Text) : async Text {
    return ("hey there " # name # "!");
  };
};
