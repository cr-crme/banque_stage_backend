import 'package:backend/repositories/mysql_helpers.dart';
import 'package:backend/repositories/repository_abstract.dart';
import 'package:backend/utils/exceptions.dart';
import 'package:common/models/enterprises/job.dart';
import 'package:common/models/generic/address.dart';
import 'package:common/models/enterprises/enterprise.dart';
import 'package:common/models/enterprises/job_list.dart';
import 'package:common/models/persons/person.dart';
import 'package:common/models/generic/phone_number.dart';
import 'package:mysql1/mysql1.dart';

abstract class EnterprisesRepository implements RepositoryAbstract {
  @override
  Future<Map<String, dynamic>> getAll() async {
    final enterprises = await _getAllEnterprises();
    return enterprises.map((key, value) => MapEntry(key, value.serialize()));
  }

  @override
  Future<Map<String, dynamic>> getById({required String id}) async {
    final enterprise = await _getEnterpriseById(id: id);
    if (enterprise == null) throw MissingDataException('Enterprise not found');

    return enterprise.serialize();
  }

  @override
  Future<void> putAll({required Map<String, dynamic> data}) async =>
      throw InvalidRequestException('Enterprises must be created individually');

  @override
  Future<void> putById(
      {required String id, required Map<String, dynamic> data}) async {
    // Update if exists, insert if not
    final previous = await _getEnterpriseById(id: id);

    final newEnterprise = previous?.copyWithData(data) ??
        Enterprise.fromSerialized(<String, dynamic>{'id': id}..addAll(data));

    await _putEnterprise(enterprise: newEnterprise, previous: previous);
  }

  Future<Map<String, Enterprise>> _getAllEnterprises();

  Future<Enterprise?> _getEnterpriseById({required String id});

  Future<void> _putEnterprise(
      {required Enterprise enterprise, required Enterprise? previous});
}

class MySqlEnterprisesRepository extends EnterprisesRepository {
  // coverage:ignore-start
  final MySqlConnection connection;
  MySqlEnterprisesRepository({required this.connection});

  @override
  Future<Map<String, Enterprise>> _getAllEnterprises(
      {String? enterpriseId}) async {
    final enterprises = await MySqlHelpers.performSelectQuery(
      connection: connection,
      tableName: 'enterprises',
      id: enterpriseId,
      subqueries: [
        MySqlJoinSubQuery(
            dataTableName: 'persons',
            asName: 'contact',
            idNameToDataTable: 'contact_id',
            idNameToMainTable: 'enterprise_id',
            relationTableName: 'enterprise_contacts',
            fieldsToFetch: ['id']),
        MySqlJoinSubQuery(
            dataTableName: 'addresses',
            asName: 'address',
            idNameToDataTable: 'address_id',
            idNameToMainTable: 'enterprise_id',
            relationTableName: 'enterprise_addresses',
            fieldsToFetch: [
              'id',
              'civic',
              'street',
              'apartment',
              'city',
              'postal_code'
            ]),
        MySqlJoinSubQuery(
            dataTableName: 'addresses',
            asName: 'headquarter_address',
            idNameToDataTable: 'address_id',
            idNameToMainTable: 'enterprise_id',
            relationTableName: 'enterprise_headquarter_addresses',
            fieldsToFetch: [
              'id',
              'civic',
              'street',
              'apartment',
              'city',
              'postal_code'
            ]),
        MySqlJoinSubQuery(
            dataTableName: 'phone_numbers',
            asName: 'phone_number',
            idNameToDataTable: 'phone_number_id',
            idNameToMainTable: 'enterprise_id',
            relationTableName: 'enterprise_phone_numbers',
            fieldsToFetch: ['id', 'phone_number']),
        MySqlJoinSubQuery(
            dataTableName: 'phone_numbers',
            asName: 'fax_number',
            idNameToDataTable: 'fax_number_id',
            idNameToMainTable: 'enterprise_id',
            relationTableName: 'enterprise_fax_numbers',
            fieldsToFetch: ['id', 'phone_number']),
        MySqlSelectSubQuery(
            dataTableName: 'enterprise_activity_types',
            asName: 'activity_types',
            idNameToDataTable: 'enterprise_id',
            fieldsToFetch: ['activity_type']),
      ],
    );

    final map = <String, Enterprise>{};
    for (final enterprise in enterprises) {
      final contactIds = (enterprise['contact'] as List?)?.map((e) => e['id']);
      final contactId = contactIds?.isEmpty ?? true ? null : contactIds!.first;
      final contacts = contactId == null
          ? null
          : await MySqlHelpers.performSelectQuery(
              connection: connection,
              tableName: 'persons',
              id: contactId,
              subqueries: [
                  MySqlSelectSubQuery(
                      dataTableName: 'addresses',
                      idNameToDataTable: 'entity_id',
                      fieldsToFetch: [
                        'id',
                        'civic',
                        'street',
                        'apartment',
                        'city',
                        'postal_code'
                      ]),
                ]);
      enterprise['contact'] =
          (contacts?.isEmpty ?? true) ? {} : contacts!.first;
      enterprise['activity_types'] =
          (enterprise['activity_types'] as List? ?? [])
              .map((e) => e['activity_type'])
              .toList();
      enterprise['phone'] = (enterprise['phone_number'] as List? ?? []).isEmpty
          ? {}
          : (enterprise['phone_number'] as List).first;
      enterprise['fax'] = (enterprise['fax_number'] as List? ?? []).isEmpty
          ? {}
          : (enterprise['fax_number'] as List).first;
      enterprise['address'] = (enterprise['address'] as List? ?? []).isEmpty
          ? {}
          : (enterprise['address'] as List).first;
      enterprise['headquarter_address'] =
          (enterprise['headquarter_address'] as List? ?? []).isEmpty
              ? {}
              : (enterprise['headquarter_address'] as List).first;

      final jobsTp = await MySqlHelpers.performSelectQuery(
        connection: connection,
        tableName: 'enterprise_jobs',
        idName: 'enterprise_id',
        id: enterprise['id'],
        subqueries: [
          MySqlSelectSubQuery(
              dataTableName: 'enterprise_job_photo_urls',
              asName: 'photo_url',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['photo_url']),
          MySqlSelectSubQuery(
              dataTableName: 'enterprise_job_comments',
              asName: 'comments',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['comment']),
          MySqlSelectSubQuery(
              dataTableName: 'enterprise_job_pre_internship_requests',
              asName: 'pre_internship_requests',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['request']),
          MySqlSelectSubQuery(
              dataTableName: 'enterprise_job_uniforms',
              asName: 'uniforms',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['status', 'uniform']),
          MySqlSelectSubQuery(
              dataTableName: 'enterprise_job_protections',
              asName: 'protections',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['status', 'protection']),
          MySqlSelectSubQuery(
              dataTableName: 'enterprise_job_incidents',
              asName: 'incidents',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['incident_type', 'incident', 'date']),
          MySqlSelectSubQuery(
              dataTableName: 'enterprise_job_sst_evaluation_questions',
              asName: 'sst_evaluations',
              idNameToDataTable: 'job_id',
              fieldsToFetch: ['question', 'answers', 'date']),
        ],
      );
      final jobs = <String, dynamic>{};
      for (final job in jobsTp) {
        jobs[job['id']] = job;
        jobs[job['id']]['photos_url'] =
            (job['photo_url'] as List?)?.map((e) => e['photo_url']).toList() ??
                [];
        jobs[job['id']]['comments'] =
            (job['comments'] as List?)?.map((e) => e['comment']).toList() ?? [];
        jobs[job['id']]['pre_internship_requests'] =
            (job['pre_internship_requests'] as List?)
                    ?.map((e) => e['request'])
                    .toList() ??
                [];
        final uniforms = job['uniforms'] as List? ?? [];
        jobs[job['id']]['uniforms'] = {
          'status': uniforms.isEmpty
              ? UniformStatus.none.index
              : uniforms.first['status'],
          'uniforms':
              (job['uniforms'] as List?)?.map((e) => e['uniform']).toList()
        };
        final protections = job['protections'] as List? ?? [];
        jobs[job['id']]['protections'] = {
          'status': protections.isEmpty
              ? ProtectionsStatus.none.index
              : protections.first['status'],
          'protections': protections.map((e) => e['protection']).toList()
        };
        jobs[job['id']]['incidents'] = {
          'severe_injuries': (job['incidents'] as List?)
                  ?.where((e) => e['incident_type'] == 'severe_injuries')
                  .toList() ??
              [],
          'verbal_abuses': (job['incidents'] as List?)
                  ?.where((e) => e['incident_type'] == 'verbal_abuses')
                  .toList() ??
              [],
          'minor_injuries': (job['incidents'] as List?)
                  ?.where((e) => e['incident_type'] == 'minor_injuries')
                  .toList() ??
              [],
        };
        jobs[job['id']]['sst_evaluations'] = {
          'questions': {
            for (final Map question in (job['sst_evaluations'] as List? ?? []))
              question['question']:
                  (question['answers'] as String?)?.split('\n') ?? []
          },
          'date': (job['sst_evaluations'] as List?)?.isEmpty ?? true
              ? 0
              : (job['sst_evaluations'] as List?)?.first['date']
        };
      }
      enterprise['jobs'] = jobs;

      map[enterprise['id'].toString()] = Enterprise.fromSerialized(enterprise);
    }

    return map;
  }

  @override
  Future<Enterprise?> _getEnterpriseById({required String id}) async =>
      (await _getAllEnterprises(enterpriseId: id))[id];

  @override
  Future<void> _putEnterprise(
          {required Enterprise enterprise,
          required Enterprise? previous}) async =>
      previous == null
          ? await _putNewEnterprise(enterprise)
          : await _putExistingEnterprise(enterprise, previous);

  Future<void> _putNewEnterprise(Enterprise enterprise) async {
    final serialized = enterprise.serialize();

    try {
      // Insert the enterprise
      await MySqlHelpers.performInsertQuery(
          connection: connection,
          tableName: 'entities',
          data: {'shared_id': serialized['id']});
      await MySqlHelpers.performInsertQuery(
          connection: connection,
          tableName: 'enterprises',
          data: {
            'id': serialized['id'],
            'version': serialized['version'],
            'name': serialized['name'],
            'recruiter_id': serialized['recruiter_id'],
            'contact_function': serialized['contact_function'],
            'website': serialized['website'],
            'neq': serialized['neq'],
          });

      // Insert the activity types
      for (final activityType in serialized['activity_types']) {
        await MySqlHelpers.performInsertQuery(
            connection: connection,
            tableName: 'enterprise_activity_types',
            data: {
              'enterprise_id': serialized['id'],
              'activity_type': activityType,
            });
      }

      // Insert jobs
      for (final jobId
          in (serialized['jobs'] as Map<String, dynamic>?)?.keys ?? []) {
        final job = serialized['jobs'][jobId];

        await MySqlHelpers.performInsertQuery(
            connection: connection,
            tableName: 'enterprise_jobs',
            data: {
              'id': job['id'],
              'version': job['version'],
              'enterprise_id': serialized['id'],
              'specialization_id': job['specialization_id'],
              'positions_offered': job['positions_offered'],
              'minimum_age': job['minimum_age'],
            });

        // Insert photo urls of the job
        for (final photoUrl in job['photos_url']) {
          await MySqlHelpers.performInsertQuery(
              connection: connection,
              tableName: 'enterprise_job_photo_urls',
              data: {
                'job_id': job['id'],
                'photo_url': photoUrl,
              });
        }

        // Insert the comments for the job
        for (final comment in job['comments']) {
          await MySqlHelpers.performInsertQuery(
              connection: connection,
              tableName: 'enterprise_job_comments',
              data: {
                'job_id': job['id'],
                'comment': comment,
              });
        }

        // Insert pre-internship requests for the job
        for (final request in job['pre_internship_requests']) {
          await MySqlHelpers.performInsertQuery(
              connection: connection,
              tableName: 'enterprise_job_pre_internship_requests',
              data: {
                'job_id': job['id'],
                'request': request,
              });
        }

        // Insert uniforms
        for (final uniform in job['uniforms']['uniforms'] ?? []) {
          await MySqlHelpers.performInsertQuery(
              connection: connection,
              tableName: 'enterprise_job_uniforms',
              data: {
                'job_id': job['id'],
                'status': job['uniforms']['status'],
                'uniform': uniform,
              });
        }

        // Insert protections
        for (final protection in job['protections']['protections'] ?? []) {
          await MySqlHelpers.performInsertQuery(
              connection: connection,
              tableName: 'enterprise_job_protections',
              data: {
                'job_id': job['id'],
                'status': job['protections']['status'],
                'protection': protection,
              });
        }

        // Insert incidents
        for (final incidentType in (job['incidents'] as Map).keys) {
          if (incidentType == 'id') continue;
          for (final incident in job['incidents'][incidentType]) {
            await MySqlHelpers.performInsertQuery(
                connection: connection,
                tableName: 'enterprise_job_incidents',
                data: {
                  'job_id': job['id'],
                  'incident_type': incidentType,
                  'incident': incident['incident'],
                  'date': incident['date'],
                });
          }
        }

        // Insert the SST evaluation
        for (final question
            in (job['sst_evaluations']['questions'] as Map).entries) {
          await MySqlHelpers.performInsertQuery(
              connection: connection,
              tableName: 'enterprise_job_sst_evaluation_questions',
              data: {
                'job_id': job['id'],
                'question': question.key,
                'answers': (question.value as List?)?.join('\n'),
                'date': job['sst_evaluations']['date'],
              });
        }
      }

      // Insert the contact
      await MySqlHelpers.performInsertPerson(
          connection: connection, person: enterprise.contact);
      await MySqlHelpers.performInsertQuery(
          connection: connection,
          tableName: 'enterprise_contacts',
          data: {
            'enterprise_id': enterprise.id,
            'contact_id': enterprise.contact.id
          });

      // Insert the addresses
      if (enterprise.address != null) {
        await MySqlHelpers.performInsertAddress(
            connection: connection,
            address: enterprise.address!,
            entityId: enterprise.id);
        await MySqlHelpers.performInsertQuery(
            connection: connection,
            tableName: 'enterprise_addresses',
            data: {
              'enterprise_id': enterprise.id,
              'address_id': enterprise.address!.id
            });
      }
      if (enterprise.headquartersAddress != null) {
        await MySqlHelpers.performInsertAddress(
            connection: connection,
            address: enterprise.headquartersAddress!,
            entityId: enterprise.id);
        await MySqlHelpers.performInsertQuery(
            connection: connection,
            tableName: 'enterprise_headquarter_addresses',
            data: {
              'enterprise_id': enterprise.id,
              'address_id': enterprise.headquartersAddress!.id
            });
      }

      // Insert the phone numbers
      await MySqlHelpers.performInsertPhoneNumber(
          connection: connection,
          phoneNumber: enterprise.phone,
          entityId: enterprise.id);
      await MySqlHelpers.performInsertQuery(
          connection: connection,
          tableName: 'enterprise_phone_numbers',
          data: {
            'enterprise_id': enterprise.id,
            'phone_number_id': enterprise.phone.id
          });
      await MySqlHelpers.performInsertPhoneNumber(
          connection: connection,
          phoneNumber: enterprise.fax,
          entityId: enterprise.id);
      await MySqlHelpers.performInsertQuery(
          connection: connection,
          tableName: 'enterprise_fax_numbers',
          data: {
            'enterprise_id': enterprise.id,
            'fax_number_id': enterprise.fax.id
          });
    } catch (e) {
      try {
        await MySqlHelpers.performDeleteQuery(
            connection: connection, tableName: 'entities', id: enterprise.id);
      } catch (e) {
        // Do nothing
      }

      rethrow;
    }
  }

  Future<void> _putExistingEnterprise(
      Enterprise enterprise, Enterprise previous) async {
    final Map<String, dynamic> toUpdate = {};
    if (enterprise.name != previous.name) toUpdate['name'] = enterprise.name;

    // TODO: Implement updating enterprise
    throw 'Not implemented yet';
  }
  // coverage:ignore-end
}

class EnterprisesRepositoryMock extends EnterprisesRepository {
  // Simulate a database with a map
  final _dummyDatabase = {
    '0': Enterprise(
      id: '0',
      name: 'My First Enterprise',
      jobs: JobList(),
      activityTypes: {ActivityTypes.magasin, ActivityTypes.entreposage},
      recruiterId: 'Recruiter 1',
      contact: Person.empty,
      address: Address.empty,
      phone: PhoneNumber.fromString('123-456-7890'),
      fax: PhoneNumber.fromString('098-765-4321'),
    ),
    '1': Enterprise(
      id: '1',
      name: 'My Second Enterprise',
      jobs: JobList(),
      activityTypes: {
        ActivityTypes.magasin,
        ActivityTypes.entreposage,
        ActivityTypes.ebenisterie
      },
      recruiterId: 'Recruiter 2',
      contact: Person.empty,
      address: Address.empty,
      phone: PhoneNumber.fromString('123-456-7890'),
      fax: PhoneNumber.fromString('098-765-4321'),
    )
  };

  @override
  Future<Map<String, Enterprise>> _getAllEnterprises() async => _dummyDatabase;

  @override
  Future<Enterprise?> _getEnterpriseById({required String id}) async =>
      _dummyDatabase[id];

  @override
  Future<void> _putEnterprise(
          {required Enterprise enterprise,
          required Enterprise? previous}) async =>
      _dummyDatabase[enterprise.id] = enterprise;
}
