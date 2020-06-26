
import 'package:flutter/material.dart';
import './../../../blocs/customer_bloc.dart';
import './../../../models/app_state_model.dart';
import '../../../ui/accounts/login/buttons.dart';
import '../../../models/checkout/checkout_form_model.dart';
import '../../../ui/checkout/place_picker.dart';
import '../../../blocs/home_bloc.dart';
import './../../../models/customer_model.dart';
import '../../color_override.dart';
import 'package:html/parser.dart';

class EditAddress extends StatefulWidget {

  final appStateModel = AppStateModel();

  CustomerBloc customerBloc;
  AsyncSnapshot<Customer> customer;

  EditAddress({Key key, this.customerBloc, this.customer}) : super(key: key);
  @override
  _EditAddressState createState() => _EditAddressState();
}

class _EditAddressState extends State<EditAddress> {
  final _formKey = GlobalKey<FormState>();

  List<Region> regions;
  TextEditingController _address1Controller = TextEditingController();
  TextEditingController _cityController = TextEditingController();
  TextEditingController _postCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.customerBloc.getCheckoutForm();
    _address1Controller.text = widget.customer.data.billing.address1;
    _cityController.text = widget.customer.data.billing.city;
    _postCodeController.text = widget.customer.data.billing.postcode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 1.0,
          title: Text(widget.appStateModel.blocks.localeText.edit),
        ),
        body: StreamBuilder<CheckoutFormModel>(
            stream: widget.customerBloc.checkoutForm,
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? buildListView(context, snapshot)
                  : Center(child: CircularProgressIndicator());
            }),
    );
  }

  Widget buildListView(BuildContext context, AsyncSnapshot<CheckoutFormModel> snapshot) {

    if(snapshot.data.countries.indexWhere((country) => country.value == widget.customer.data.billing.country) != -1) {
      regions = snapshot.data.countries.singleWhere((country) => country.value == widget.customer.data.billing.country).regions;
    } else if(snapshot.data.countries.indexWhere((country) => country.value == widget.customer.data.billing.country) == -1) {
      widget.customer.data.billing.country = snapshot.data.countries.first.value;
    } if(regions != null && regions.isNotEmpty) {
      widget.customer.data.billing.state = regions.any((z) => z.value == widget.customer.data.billing.state) ? widget.customer.data.billing.state
          : regions.first.value;
    }

    if(_address1Controller.text.isEmpty)
      _address1Controller.text = snapshot.data.billingAddress1;
    if(_cityController.text.isEmpty)
      _cityController.text = snapshot.data.billingCity;
    if(_postCodeController.text.isEmpty)
      _postCodeController.text = snapshot.data.billingPostcode;

    return ListView(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FlatButton(
                    colorBrightness: Theme.of(context).brightness,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:<Widget>[
                        Icon(Icons.add_location),
                        Text(widget.appStateModel.blocks.localeText.selectLocation)
                      ], ),
                    onPressed: () {
                      showPlacePicker(snapshot);
                    },
                  ),
                  PrimaryColorOverride(
                    child: TextFormField(
                      initialValue: widget.customer.data.firstName,
                      decoration: InputDecoration(labelText: widget.appStateModel.blocks.localeText.firstName),
                      validator: (value) {
                        if (value.isEmpty) {
                          return widget.appStateModel.blocks.localeText.pleaseEnterFirstName;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        widget.customer.data.firstName =
                            value;
                      },
                    ),
                  ),
                  SizedBox(height: 12.0),
                  PrimaryColorOverride(
                    child: TextFormField(
                      initialValue: widget.customer.data.lastName,
                      decoration: InputDecoration(labelText: widget.appStateModel.blocks.localeText.lastName),
                      validator: (value) {
                        if (value.isEmpty) {
                          return widget.appStateModel.blocks.localeText.pleaseEnterLastName;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        widget.customer.data.lastName =
                            value;
                      },
                    ),
                  ),
                  SizedBox(height: 12.0),
                  PrimaryColorOverride(
                    child: TextFormField(
                      controller: _address1Controller,
                      decoration: InputDecoration(labelText: widget.appStateModel.blocks.localeText.address),
                      validator: (value) {
                        if (value.isEmpty) {
                          return widget.appStateModel.blocks.localeText.selectLocation;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        widget.customer.data.billing.address1 =
                            value;
                      },
                    ),
                  ),
                  /*SizedBox(height: 12.0),
                  PrimaryColorOverride(
                    child: TextFormField(
                      initialValue: widget.customer.data.billing.address2,
                      decoration: InputDecoration(labelText: 'Address2'),
                      onSaved: (value) {
                        widget.customer.data.billing.address2 =
                            value;
                      },
                    ),
                  ),*/
                  SizedBox(height: 12.0),
                  PrimaryColorOverride(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: widget.appStateModel.blocks.localeText.city,
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return widget.appStateModel.blocks.localeText.pleaseEnterCity;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        widget.customer.data.billing..city = value;
                      },
                    ),
                  ),
                  SizedBox(height: 12.0),
                  PrimaryColorOverride(
                    child: TextFormField(
                      controller: _postCodeController,
                      decoration: InputDecoration(labelText: widget.appStateModel.blocks.localeText.pincode),
                      onSaved: (value) {
                        widget.customer.data.billing.postcode =
                            value;
                      },
                    ),
                  ),
                  SizedBox(height: 12.0),
                  PrimaryColorOverride(
                    child: TextFormField(
                      initialValue: widget.customer.data.billing.email,
                      decoration: InputDecoration(labelText: widget.appStateModel.blocks.localeText.email),
                      onSaved: (value) {
                        widget.customer.data.billing.email = value;
                      },
                    ),
                  ),
                  SizedBox(height: 12.0),
                  PrimaryColorOverride(
                    child: TextFormField(
                      initialValue: widget.customer.data.billing.phone,
                      decoration: InputDecoration(labelText: widget.appStateModel.blocks.localeText.phoneNumber),
                      validator: (value) {
                        if (value.isEmpty) {
                          return widget.appStateModel.blocks.localeText.pleaseEnterPhoneNumber;
                        }
                        return null;
                      },
                      onSaved: (value) {
                        widget.customer.data.billing.phone = value;
                      },
                    ),
                  ),
                  SizedBox(height: 20,),
                  DropdownButton<String>(
                    value: widget.customer.data.billing.country,
                    hint: Text(widget.appStateModel.blocks.localeText.country),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down),
                    iconSize: 24,
                    elevation: 16,
                    underline: Container(
                      height: 2,
                      color: Theme.of(context).dividerColor,
                    ),
                    onChanged: (String newValue) {
                      setState(() {
                        widget.customer.data.billing.country =
                            newValue;
                      });
                    },
                    items: snapshot.data.countries
                        .map<DropdownMenuItem<String>>(
                            (value) {
                          return DropdownMenuItem<String>(
                            value: value.value != null ? value.value : '',
                            child: Text(_parseHtmlString(value.label)),
                          );
                        }).toList(),
                  ),
                  (regions != null && regions.isNotEmpty) ? Column(
                    children: <Widget>[
                      SizedBox(height: 20,),
                      DropdownButton<String>(
                        value: widget.customer.data.billing.state,
                        hint: Text(widget.appStateModel.blocks.localeText.states),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        underline: Container(
                          height: 2,
                          color: Theme.of(context).dividerColor,
                        ),
                        onChanged: (String newValue) {
                          setState(() {
                            widget.customer.data.billing.state =
                                newValue;
                          });
                        },
                        items: regions
                            .map<DropdownMenuItem<String>>(
                                (value) {
                              return DropdownMenuItem<String>(
                                value: value.value != null ? value.value : '',
                                child: Text(_parseHtmlString(value.label)),
                              );
                            }).toList(),
                      ),
                    ],
                  ) : PrimaryColorOverride(
                    child: TextFormField(
                      initialValue: widget.customer.data.billing.state,
                      decoration: InputDecoration(labelText: widget.appStateModel.blocks.localeText.state),
                      validator: (value) {
                        if (value.isEmpty) {
                          return widget.appStateModel.blocks.localeText.pleaseEnterState;
                        }
                      },
                      onSaved: (val) => setState(() =>
                      widget.customerBloc.formData['billing_state'] = val),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AccentButton(
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                        widget.customerBloc.addressFormData['billing_first_name'] = widget.customer.data.billing.firstName;
                        widget.customerBloc.addressFormData['billing_last_name'] = widget.customer.data.billing.lastName;
                        widget.customerBloc.addressFormData['billing_address_1'] = widget.customer.data.billing.address1;
                        //widget.customerBloc.addressFormData['billing_address_2'] = widget.customer.data.billing.address2;
                        widget.customerBloc.addressFormData['billing_city'] = widget.customer.data.billing.city;
                        widget.customerBloc.addressFormData['billing_postcode'] = widget.customer.data.billing.postcode;
                        widget.customerBloc.addressFormData['billing_email'] = widget.customer.data.billing.email;
                        widget.customerBloc.addressFormData['billing_phone'] = widget.customer.data.billing.phone;
                        widget.customerBloc.addressFormData['billing_country'] = widget.customer.data.billing.country != null ? widget.customer.data.billing.country : '';
                        widget.customerBloc.addressFormData['billing_state'] = widget.customer.data.billing.state != null ? widget.customer.data.billing.state : '';
                        widget.customerBloc.updateAddress();
                        Navigator.pop(context);
                      }
                    },
                    showProgress: false,
                    text: widget.appStateModel.blocks.localeText.localeTextContinue),
              ],
            ),
          ),
        ],
      );
  }

  void showPlacePicker(AsyncSnapshot<CheckoutFormModel> snapshot) async {
    LocationResult result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PlacePicker()));
    if(result != null) {
      setState(() {
        _address1Controller.text = result.formattedAddress;
        _cityController.text = result.city;
        _postCodeController.text = result.pinCode;
      });
      if (snapshot.data.countries.indexWhere((country) =>
      country.value == result.country) != -1) {
        setState(() {
          snapshot.data.billingCountry = result.country;
        });
        regions = snapshot.data.countries
            .singleWhere((country) => country.value == result.country)
            .regions;
      } else if (snapshot.data.countries.length != 0) {
        snapshot.data.billingCountry = snapshot.data.countries.first.value;
      }
      if (regions != null) {
        snapshot.data.billingState =
        regions.any((z) => z.value == result.state) ? result.state
            : regions.first.value;
      }
    }
  }
}

String _parseHtmlString(String htmlString) {
  var document = parse(htmlString);

  String parsedString = parse(document.body.text).documentElement.text;

  return parsedString;
}

