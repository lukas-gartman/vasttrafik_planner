class Line {
  String name;
  String backgroundColor;
  String foregroundColor;
  String borderColor;
  String transportType;

  Line(this.name, this.backgroundColor, this.foregroundColor, this.borderColor, this.transportType);
  Line.fromJson(Map<String, dynamic> json):
    name = json["shortName"] ?? json["name"],
    backgroundColor = json["backgroundColor"],
    foregroundColor = json["foregroundColor"],
    borderColor = json["borderColor"],
    transportType = json["transportMode"];

  Map<String, dynamic> toJson() => {
    "shortName": name,
    "backgroundColor": backgroundColor,
    "foregroundColor": foregroundColor,
    "borderColor": borderColor,
    "transportMode": transportType,
  };
}